// Doctor Chat — Reuses the same chat logic as patient chat
// The chat system is role-agnostic since both sides use the same messages API
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
// models imported via widgets

class DoctorChatPage extends StatefulWidget {
  const DoctorChatPage({super.key});
  @override
  State<DoctorChatPage> createState() => _State();
}

class _State extends State<DoctorChatPage> {
  String? _selectedUserId;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchCurrent());
  }

  @override
  void dispose() { _pollTimer?.cancel(); _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _fetchCurrent() {
    if (_selectedUserId == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    context.read<AppProvider>().fetchMessages(auth.user!.id, _selectedUserId!);
  }

  void _send() {
    if (_msgCtrl.text.trim().isEmpty || _selectedUserId == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    context.read<AppProvider>().sendMessage(auth.user!.id, _selectedUserId!, _msgCtrl.text.trim());
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: _selectedUserId != null,
        leading: _selectedUserId != null ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedUserId = null)) : null,
        title: Text(_selectedUserId != null ? context.read<AppProvider>().getUserName(_selectedUserId!) : 'Chat'),
      ),
      body: Consumer2<AuthProvider, AppProvider>(builder: (ctx, auth, app, _) {
        if (auth.user == null) return const SizedBox();
        final uid = auth.user!.id;

        final activeChatId = app.activeChatUserId;
        if (activeChatId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedUserId = activeChatId;
            });
            app.setActiveChatUserId(null);
            _fetchCurrent();
          });
        }

        final contactIds = <String>{};
        for (final m in app.messages) {
          if (m.senderId == uid) contactIds.add(m.receiverId);
          if (m.receiverId == uid) contactIds.add(m.senderId);
        }
        for (final a in app.appointments) {
          if (a.doctor?.userId == uid && a.patient?.userId != null) contactIds.add(a.patient!.userId);
          if (a.patient?.userId == uid && a.doctor?.userId != null) contactIds.add(a.doctor!.userId);
        }
        final contacts = contactIds.toList();

        final unknownIds = contacts.where((id) => app.getUserName(id) == 'User').toList();
        if (unknownIds.isNotEmpty) Future.microtask(() => app.fetchUsers(unknownIds));



        if (_selectedUserId == null) {
          return _buildContactList(contacts, uid, app);
        }
        return _buildChatArea(uid, app);
      }),
    );
  }

  Widget _buildContactList(List<String> contacts, String uid, AppProvider app) {
    if (contacts.isEmpty) {
      return const EmptyState(icon: Icons.chat_bubble_outline, title: 'Belum ada percakapan', subtitle: 'Pasien akan muncul di sini setelah booking');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: contacts.length,
      itemBuilder: (ctx, i) {
        final cid = contacts[i];
        final name = app.getUserName(cid);
        final msgs = app.getMessagesBetweenUsers(uid, cid);
        final lastMsg = msgs.isNotEmpty ? msgs.last.content : 'Belum ada pesan';
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: AvatarInitials(name: name, size: 44),
            title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            onTap: () { setState(() => _selectedUserId = cid); _fetchCurrent(); },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
    );
  }

  Widget _buildChatArea(String uid, AppProvider app) {
    final msgs = app.getMessagesBetweenUsers(uid, _selectedUserId!);
    return Column(children: [
      Expanded(
        child: msgs.isEmpty
            ? const EmptyState(icon: Icons.forum_outlined, title: 'Belum ada pesan', subtitle: 'Kirim pesan pertama')
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: msgs.length,
                itemBuilder: (ctx, i) {
                  final m = msgs[i];
                  final isMe = m.senderId == uid;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                        border: isMe ? null : Border.all(color: AppTheme.border),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(m.content, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text(formatTime(m.createdAt), style: TextStyle(fontSize: 10, color: isMe ? Colors.white.withOpacity(0.7) : AppTheme.textMuted)),
                      ]),
                    ),
                  );
                },
              ),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.border))),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _msgCtrl,
            decoration: InputDecoration(hintText: 'Tulis pesan...', filled: true, fillColor: AppTheme.surfaceDim, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            onSubmitted: (_) => _send(),
          )),
          const SizedBox(width: 8),
          CircleAvatar(backgroundColor: AppTheme.primary, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _send)),
        ]),
      ),
    ]);
  }
}
