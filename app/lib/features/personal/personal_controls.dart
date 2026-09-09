import 'package:flutter/material.dart';

import '../../domain/user_models.dart';
import '../../domain/user_repository.dart';

class FavoriteIconButton extends StatefulWidget {
  const FavoriteIconButton({
    required this.favorite,
    required this.objectLabel,
    required this.onChanged,
    super.key,
  });

  final bool favorite;
  final String objectLabel;
  final Future<void> Function(bool enabled) onChanged;

  @override
  State<FavoriteIconButton> createState() => _FavoriteIconButtonState();
}

class CollectedControl extends StatefulWidget {
  const CollectedControl({
    required this.collected,
    required this.onChanged,
    super.key,
  });

  final bool collected;
  final Future<void> Function(bool enabled) onChanged;

  @override
  State<CollectedControl> createState() => _CollectedControlState();
}

class _CollectedControlState extends State<CollectedControl> {
  var _busy = false;

  Future<void> _change(bool enabled) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onChanged(enabled);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The collection mark could not be saved. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      key: const ValueKey('collected-control'),
      selected: widget.collected,
      showCheckmark: true,
      avatar: _busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      label: const Text('Handbook entry collected'),
      onSelected: _busy ? null : _change,
    );
  }
}

class _FavoriteIconButtonState extends State<FavoriteIconButton> {
  var _busy = false;

  Future<void> _change() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onChanged(!widget.favorite);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The favorite could not be saved. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.favorite ? 'Remove' : 'Add';
    return IconButton(
      key: ValueKey('favorite-${widget.objectLabel}'),
      tooltip: '$action ${widget.objectLabel} favorite',
      onPressed: _busy ? null : _change,
      icon: _busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              widget.favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
    );
  }
}

class PersonalNotesSection extends StatefulWidget {
  const PersonalNotesSection({
    required this.repository,
    required this.object,
    super.key,
  });

  final UserRepository repository;
  final ObjectRef object;

  @override
  State<PersonalNotesSection> createState() => _PersonalNotesSectionState();
}

class _PersonalNotesSectionState extends State<PersonalNotesSection> {
  final _controller = TextEditingController();
  var _notes = const <PersonalNote>[];
  String? _editingNoteId;
  Object? _error;
  var _loading = true;
  var _saving = false;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PersonalNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.object.key != widget.object.key ||
        oldWidget.object.datasetId != widget.object.datasetId) {
      _controller.clear();
      _editingNoteId = null;
      _load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final notes = await widget.repository.getNotes(widget.object);
      if (mounted && generation == _generation) {
        setState(() {
          _notes = notes;
          _loading = false;
        });
      }
    } on Object catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving || _controller.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.saveNote(
        NoteDraft(
          noteId: _editingNoteId,
          object: widget.object,
          content: _controller.text,
        ),
      );
      if (!mounted) {
        return;
      }
      _controller.clear();
      _editingNoteId = null;
      await _load();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The note could not be saved. Your draft is still here.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _edit(PersonalNote note) {
    setState(() {
      _editingNoteId = note.noteId;
      _controller.text = note.content;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingNoteId = null;
      _controller.clear();
    });
  }

  Future<void> _delete(PersonalNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This removes the note from this device.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await widget.repository.deleteNote(note.noteId);
      if (_editingNoteId == note.noteId) {
        _cancelEdit();
      }
      await _load();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The note could not be deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          key: ValueKey('note-editor-${widget.object.key}'),
          controller: _controller,
          minLines: 3,
          maxLines: 8,
          maxLength: 10000,
          decoration: const InputDecoration(
            labelText: 'Personal note',
            hintText: 'Saved only on this device',
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              key: const ValueKey('save-note'),
              onPressed: _saving || _controller.text.trim().isEmpty
                  ? null
                  : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_editingNoteId == null ? 'Save note' : 'Save edit'),
            ),
            if (_editingNoteId != null)
              TextButton(onPressed: _cancelEdit, child: const Text('Cancel')),
          ],
        ),
        const SizedBox(height: 14),
        if (_loading)
          const LinearProgressIndicator()
        else if (_error != null)
          Row(
            children: <Widget>[
              const Expanded(child: Text('Saved notes could not be loaded.')),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          )
        else if (_notes.isEmpty)
          const Text('No notes saved for this item.')
        else
          ..._notes.map(
            (note) => Card.outlined(
              child: ListTile(
                title: Text(note.content),
                subtitle: Text('Updated ${note.updatedAtUtc}'),
                trailing: Wrap(
                  spacing: 0,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Edit note',
                      onPressed: () => _edit(note),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete note',
                      onPressed: () => _delete(note),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
