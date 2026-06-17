import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
// models imported via widgets

class PatientChatPage extends StatefulWidget {
  const PatientChatPage({super.key});
  @override
  State<PatientChatPage> createState() => _State();
}

class _State extends State<PatientChatPage> {
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
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

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
        leading: _selectedUserId != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedUserId = null))
            : null,
        title: Text(_selectedUserId != null
            ? context.read<AppProvider>().getUserName(_selectedUserId!)
            : 'Chat'),
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

        // Build contact list from messages and appointments
        final contactIds = <String>{};
        for (final m in app.messages) {
          if (m.senderId == uid) contactIds.add(m.receiverId);
          if (m.receiverId == uid) contactIds.add(m.senderId);
        }
        for (final a in app.appointments) {
          if (a.patient?.userId == uid && a.doctor?.userId != null) contactIds.add(a.doctor!.userId);
          if (a.doctor?.userId == uid && a.patient?.userId != null) contactIds.add(a.patient!.userId);
        }
        final contacts = contactIds.toList();

        // Fetch user names for contacts
        final unknownIds = contacts.where((id) => app.getUserName(id) == 'User').toList();
        if (unknownIds.isNotEmpty) {
          Future.microtask(() => app.fetchUsers(unknownIds));
        }



        // Show contact list or chat
        if (_selectedUserId == null) {
          return _ContactList(
            contacts: contacts, selectedId: _selectedUserId,
            currentUserId: uid, app: app,
            onSelect: (id) { setState(() => _selectedUserId = id); _fetchCurrent(); },
          );
        }
        return _ChatArea(
          userId: uid, otherId: _selectedUserId!, app: app,
          msgCtrl: _msgCtrl, scrollCtrl: _scrollCtrl,
          onSend: _send, onBack: () => setState(() => _selectedUserId = null),
        );
      }),
    );
  }
}

// ── Contact List ────────────────────────────────────────────
class _ContactList extends StatelessWidget {
  final List<String> contacts;
  final String? selectedId;
  final String currentUserId;
  final AppProvider app;
  final void Function(String) onSelect;

  const _ContactList({required this.contacts, required this.selectedId, required this.currentUserId, required this.app, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const EmptyState(icon: Icons.chat_bubble_outline, title: 'Belum ada percakapan', subtitle: 'Mulai chat dengan mengunjungi dokter');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: contacts.length,
      itemBuilder: (ctx, i) {
        final contactId = contacts[i];
        final name = app.getUserName(contactId);
        final msgs = app.getMessagesBetweenUsers(currentUserId, contactId);
        final lastMsg = msgs.isNotEmpty ? msgs.last.content : 'Belum ada pesan';
        final isSelected = selectedId == contactId;
        final unread = msgs.where((m) => m.receiverId == currentUserId && !m.isRead).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? AppTheme.primary.withOpacity(0.3) : AppTheme.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: AvatarInitials(name: name, size: 44),
            title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            trailing: unread > 0 ? Container(
              padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: Text('$unread', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
            ) : null,
            onTap: () => onSelect(contactId),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
    );
  }
}

// ── Chat Area ───────────────────────────────────────────────
class _ChatArea extends StatelessWidget {
  final String userId, otherId;
  final AppProvider app;
  final TextEditingController msgCtrl;
  final ScrollController scrollCtrl;
  final VoidCallback onSend;
  final VoidCallback? onBack;

  const _ChatArea({required this.userId, required this.otherId, required this.app, required this.msgCtrl, required this.scrollCtrl, required this.onSend, this.onBack});

  @override
  Widget build(BuildContext context) {
    final msgs = app.getMessagesBetweenUsers(userId, otherId);

    return Column(children: [
      // Messages
      Expanded(
        child: msgs.isEmpty
            ? const EmptyState(icon: Icons.forum_outlined, title: 'Belum ada pesan', subtitle: 'Kirim pesan pertama')
            : ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: msgs.length,
                itemBuilder: (ctx, i) {
                  final m = msgs[i];
                  final isMe = m.senderId == userId;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
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
      // Input
      Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.border))),
        child: Row(children: [
          Expanded(child: TextField(
            controller: msgCtrl,
            decoration: InputDecoration(
              hintText: 'Tulis pesan...',
              filled: true, fillColor: AppTheme.surfaceDim,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onSubmitted: (_) => onSend(),
          )),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primary,
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: onSend),
          ),
        ]),
      ),
    ]);
  }
}
