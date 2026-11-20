import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../ads.dart';
import '../data/occasions.dart';
import '../data/styles.dart';
import '../widgets/greeting_card.dart';

class EditorScreen extends StatefulWidget {
  final Occasion occasion;

  const EditorScreen({super.key, required this.occasion});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _cardKey = GlobalKey();
  late final TextEditingController _message;
  final _to = TextEditingController();
  final _from = TextEditingController();
  late int _styleIndex;
  double _fontScale = 1.0;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _styleIndex = widget.occasion.defaultStyle;
    _message = TextEditingController(text: widget.occasion.phrases.first);
    for (final c in [_message, _to, _from]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _message.dispose();
    _to.dispose();
    _from.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    FocusScope.of(context).unfocus();
    try {
      // نستنى الإطار الجاي عشان البطاقة تكون مرسومة بآخر تعديل
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(data!.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حصلت مشكلة في المشاركة، جرّب تاني')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = cardStyles[_styleIndex];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.occasion.title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: GreetingCard(
                    style: style,
                    message: _message.text,
                    toName: _to.text,
                    fromName: _from.text,
                    fontScale: _fontScale,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('اختار عبارة جاهزة', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.occasion.phrases.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final phrase = widget.occasion.phrases[i];
                final selected = phrase == _message.text;
                return SizedBox(
                  width: 210,
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _message.text = phrase,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            phrase.replaceAll('\n', ' - '),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'أو اكتب تهنئتك بنفسك',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text('شكل البطاقة', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cardStyles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final s = cardStyles[i];
                final selected = i == _styleIndex;
                return Tooltip(
                  message: s.name,
                  child: GestureDetector(
                    onTap: () => setState(() => _styleIndex = i),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: s.colors),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : Colors.black12,
                          width: selected ? 3 : 1,
                        ),
                      ),
                      child: selected
                          ? Icon(Icons.check, color: s.text)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.text_fields),
              const SizedBox(width: 8),
              const Text('حجم الخط'),
              Expanded(
                child: Slider(
                  value: _fontScale,
                  min: 0.6,
                  max: 1.5,
                  onChanged: (v) => setState(() => _fontScale = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _to,
            decoration: const InputDecoration(
              labelText: 'إلى (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _from,
            decoration: const InputDecoration(
              labelText: 'من (اختياري)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sharing ? null : _share,
        icon: _sharing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.share),
        label: const Text('مشاركة البطاقة'),
      ),
      bottomNavigationBar: const BannerAdBox(),
    );
  }
}
