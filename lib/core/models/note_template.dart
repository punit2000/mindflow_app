class NoteTemplate {
  final String name;
  final String emoji;
  final String titlePlaceholder;
  final String contentPlaceholder;
  final bool isChecklist;
  final List<String> checklistItems;

  const NoteTemplate({
    required this.name,
    required this.emoji,
    required this.titlePlaceholder,
    required this.contentPlaceholder,
    this.isChecklist = false,
    this.checklistItems = const [],
  });

  static const List<NoteTemplate> templates = [
    NoteTemplate(
      name: 'Meeting Notes',
      emoji: '🤝',
      titlePlaceholder: 'Meeting Notes — [Topic]',
      contentPlaceholder: '## Attendees\n\n## Agenda\n1. \n2. \n\n## Key Decisions\n\n## Action Items\n- [ ] \n\n## Next Steps\n',
    ),
    NoteTemplate(
      name: 'Daily Journal',
      emoji: '📔',
      titlePlaceholder: 'Journal — [Date]',
      contentPlaceholder: '## How I\'m feeling\n\n## Today\'s highlights\n\n## What I\'m grateful for\n1. \n2. \n3. \n\n## Tomorrow\'s intention\n',
    ),
    NoteTemplate(
      name: 'Project Brief',
      emoji: '🚀',
      titlePlaceholder: 'Project Brief — [Name]',
      contentPlaceholder: '## Problem Statement\n\n## Goals\n\n## Scope\n### In scope\n\n### Out of scope\n\n## Timeline\n\n## Resources Needed\n',
    ),
    NoteTemplate(
      name: 'Book Summary',
      emoji: '📚',
      titlePlaceholder: 'Book: [Title] by [Author]',
      contentPlaceholder: '## Key Ideas\n1. \n2. \n3. \n\n## Favourite Quotes\n> \n\n## What I\'ll Apply\n\n## Rating\n⭐⭐⭐⭐⭐\n',
    ),
    NoteTemplate(
      name: 'Shopping List',
      emoji: '🛒',
      titlePlaceholder: 'Shopping List',
      contentPlaceholder: '',
      isChecklist: true,
      checklistItems: ['', '', ''],
    ),
    NoteTemplate(
      name: 'Brainstorm',
      emoji: '💡',
      titlePlaceholder: 'Brainstorm — [Topic]',
      contentPlaceholder: '## The Challenge\n\n## Wild Ideas (no filter!)\n- \n- \n- \n\n## Best Ideas\n\n## Next Step\n',
    ),
  ];
}
