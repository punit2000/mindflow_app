import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/pdf_annotation.dart';
import '../../../core/models/pdf_document.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/route_exit.dart';
import '../../providers/notes_provider.dart';
import '../../providers/pdf_library_provider.dart';
import '../notes/note_editor_screen.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({super.key, required this.document});

  final PdfDocument document;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  final PdfViewerController _controller = PdfViewerController();
  int _currentPage = 1;
  int? _pageCount;
  bool _focusMode = false;
  bool _annotateMode = false;
  int _annotationColorIndex = 0;
  late List<int> _bookmarks;
  late List<PdfAnnotation> _annotations;
  List<List<double>>? _draftPoints;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.document.lastReadPage;
    _bookmarks = List.from(widget.document.bookmarks);
    _annotations = List.from(widget.document.annotations);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final documentId = widget.document.id;
    final currentPage = _currentPage;
    final pageCount = _pageCount;
    final notifier = ref.read(pdfLibraryProvider.notifier);
    waitForRouteExit().then((_) {
      notifier.saveReadingProgress(
        documentId,
        page: currentPage,
        pageCount: pageCount,
      );
    });
    _controller.dispose();
    super.dispose();
  }

  void _toggleFocusMode() {
    setState(() => _focusMode = !_focusMode);
    SystemChrome.setEnabledSystemUIMode(
      _focusMode ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarks.contains(_currentPage)) {
        _bookmarks.remove(_currentPage);
      } else {
        _bookmarks.add(_currentPage);
        _bookmarks.sort();
      }
    });
    ref
        .read(pdfLibraryProvider.notifier)
        .updateBookmarks(widget.document.id, _bookmarks);
  }

  void _toggleAnnotateMode() {
    setState(() {
      _annotateMode = !_annotateMode;
      _draftPoints = null;
    });
  }

  void _saveAnnotations() {
    ref
        .read(pdfLibraryProvider.notifier)
        .updateAnnotations(widget.document.id, _annotations);
  }

  void _clearPageAnnotations() {
    setState(() {
      _annotations =
          _annotations.where((a) => a.page != _currentPage).toList();
      _draftPoints = null;
    });
    _saveAnnotations();
  }

  void _onPanStart(DragStartDetails details, Size canvasSize) {
    if (!_annotateMode) return;
    final dx = (details.localPosition.dx / canvasSize.width).clamp(0.0, 1.0);
    final dy = (details.localPosition.dy / canvasSize.height).clamp(0.0, 1.0);
    setState(() => _draftPoints = [[dx, dy]]);
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (!_annotateMode || _draftPoints == null) return;
    final dx = (details.localPosition.dx / canvasSize.width).clamp(0.0, 1.0);
    final dy = (details.localPosition.dy / canvasSize.height).clamp(0.0, 1.0);
    setState(() => _draftPoints!.add([dx, dy]));
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_annotateMode || _draftPoints == null || _draftPoints!.isEmpty) return;
    final annotation = PdfAnnotation(
      id: const Uuid().v4(),
      page: _currentPage,
      type: 'ink',
      colorIndex: _annotationColorIndex,
      points: List.from(_draftPoints!),
    );
    setState(() {
      _annotations.add(annotation);
      _draftPoints = null;
    });
    _saveAnnotations();
  }

  void _showBookmarks() {
    if (_bookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bookmarks yet. Tap the bookmark icon to add one.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bookmarks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _bookmarks.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Page ${_bookmarks[index]}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () {
                      setState(() => _bookmarks.removeAt(index));
                      ref
                          .read(pdfLibraryProvider.notifier)
                          .updateBookmarks(widget.document.id, _bookmarks);
                      Navigator.pop(context);
                      waitForRouteExit().then((_) {
                        if (_bookmarks.isNotEmpty && mounted) {
                          _showBookmarks();
                        }
                      });
                    },
                  ),
                  onTap: () {
                    _controller.jumpToPage(_bookmarks[index]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createLinkedNote() {
    final linkedNoteId = widget.document.linkedNoteId;
    if (linkedNoteId != null) {
      final existing = ref.read(notesProvider.notifier).getNoteById(linkedNoteId);
      if (existing != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditorScreen(initialNote: existing)),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          linkedSourceId: widget.document.id,
          initialTitle: widget.document.title,
          initialContent: '## Notes on: ${widget.document.title}\n\n',
        ),
      ),
    ).then((noteId) async {
      if (noteId is String) {
        await waitForRouteExit();
        if (mounted) {
          ref.read(pdfLibraryProvider.notifier).setLinkedNote(widget.document.id, noteId);
        }
      }
    });
  }

  void _previousPage() {
    if (_currentPage > 1) _controller.previousPage();
  }

  void _nextPage() {
    if (_pageCount == null || _currentPage < _pageCount!) _controller.nextPage();
  }

  void _saveProgress(int page) {
    _currentPage = page;
    ref.read(pdfLibraryProvider.notifier).saveReadingProgress(
          widget.document.id,
          page: page,
          pageCount: _pageCount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.document.filePath);
    if (!file.existsSync()) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.document.title)),
        body: const Center(child: Text('This PDF file is no longer available.')),
      );
    }

    return Scaffold(
      appBar: _focusMode
          ? null
          : AppBar(
              title: Text(widget.document.title),
              actions: [
                if (_pageCount != null) Center(child: Text('$_currentPage / $_pageCount')),
                IconButton(
                  icon: Icon(
                    _bookmarks.contains(_currentPage)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                  ),
                  tooltip: _bookmarks.contains(_currentPage)
                      ? 'Remove bookmark'
                      : 'Add bookmark',
                  onPressed: _toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.bookmarks_rounded),
                  tooltip: 'Show bookmarks',
                  onPressed: _showBookmarks,
                ),
                IconButton(
                  icon: Icon(
                    _annotateMode ? Icons.draw_rounded : Icons.draw_outlined,
                    color: _annotateMode ? AppColors.primary : null,
                  ),
                  tooltip: _annotateMode ? 'Stop annotating' : 'Annotate',
                  onPressed: _toggleAnnotateMode,
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded),
                  tooltip: 'Focus mode',
                  onPressed: _toggleFocusMode,
                ),
              ],
            ),
      floatingActionButton: null,
      body: Stack(
        children: [
          SfPdfViewer.file(
            file,
            controller: _controller,
            initialPageNumber: _currentPage,
            // Keep one full page on screen at a time, like an e-reader.
            // The viewer supports horizontal swipes; the bottom arrows remain
            // available as an accessible, precise alternative.
            pageLayoutMode: PdfPageLayoutMode.single,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            onDocumentLoaded: (details) {
              setState(() => _pageCount = details.document.pages.count);
            },
            onPageChanged: (details) {
              setState(() => _currentPage = details.newPageNumber);
              _saveProgress(details.newPageNumber);
            },
          ),
          if (_focusMode)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                  tooltip: 'Exit focus mode',
                  onPressed: _toggleFocusMode,
                ),
              ),
            ),
          if (_annotateMode)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  final pageAnnotations = _annotations
                      .where((a) => a.page == _currentPage)
                      .toList();
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _onPanStart(d, size),
                    onPanUpdate: (d) => _onPanUpdate(d, size),
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      size: size,
                      painter: _AnnotationPainter(
                        annotations: pageAnnotations,
                        draftPoints: _draftPoints,
                        colors: AppColors.annotationColors,
                        canvasSize: size,
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_annotateMode)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < AppColors.annotationColors.length; i++)
                        InkWell(
                          onTap: () => setState(() => _annotationColorIndex = i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.annotationColors[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _annotationColorIndex == i
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                        tooltip: 'Clear page',
                        onPressed: _clearPageAnnotations,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_focusMode)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.all(12),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(28),
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _currentPage > 1 ? _previousPage : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                          tooltip: 'Previous page',
                        ),
                        Text('Page $_currentPage${_pageCount == null ? '' : ' of $_pageCount'}'),
                        IconButton(
                          onPressed: _pageCount == null || _currentPage < _pageCount!
                              ? _nextPage
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                          tooltip: 'Next page',
                        ),
                        Container(
                          width: 1,
                          height: 22,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                        ),
                        IconButton(
                          onPressed: _createLinkedNote,
                          icon: const Icon(Icons.edit_note_rounded),
                          tooltip: 'Add note',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints ink strokes (stored in normalized coordinates) onto the overlay.
class _AnnotationPainter extends CustomPainter {
  final List<PdfAnnotation> annotations;
  final List<List<double>>? draftPoints;
  final List<Color> colors;
  final Size canvasSize;

  _AnnotationPainter({
    required this.annotations,
    required this.draftPoints,
    required this.colors,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      final color = colors[annotation.colorIndex % colors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < annotation.points.length; i++) {
        final p = annotation.points[i];
        final point = Offset(p[0] * canvasSize.width, p[1] * canvasSize.height);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    if (draftPoints != null && draftPoints!.isNotEmpty) {
      final color = colors.first;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < draftPoints!.length; i++) {
        final p = draftPoints![i];
        final point = Offset(p[0] * canvasSize.width, p[1] * canvasSize.height);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.draftPoints != draftPoints ||
        oldDelegate.canvasSize != canvasSize;
  }
}
