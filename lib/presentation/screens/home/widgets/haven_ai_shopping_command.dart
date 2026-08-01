class HavenAiShoppingCommand {
  const HavenAiShoppingCommand({
    required this.itemName,
    this.quantity = '',
    this.listTitle,
    this.items = const [],
  });

  final String itemName;
  final String quantity;
  final String? listTitle;
  final List<HavenAiShoppingItem> items;

  bool get hasMultipleItems => items.length > 1;

  static HavenAiShoppingCommand? parse(String input) {
    final text = input.trim();
    final lower = text.toLowerCase();
    final mentionsShopping =
        lower.contains('shopping') ||
        lower.contains('grocery') ||
        lower.contains('list');
    if (!lower.contains('shopping') &&
        !lower.contains('grocery') &&
        !lower.startsWith('buy ') &&
        !lower.startsWith('get ') &&
        !lower.startsWith('add ') &&
        !lower.startsWith('put ')) {
      return null;
    }

    final namedListMatch = RegExp(
      r'^(?:please\s+)?(?:create|make|start|add)\s+(?:a\s+)?(?:shopping|grocery)\s+list\s+(?:named|called|titled)\s*[:,\-]?\s*(.+?)\s*[,;.]?\s+(?:with|containing)\s+(?:(?:these|this|the)\s+|the\s+following\s+)?items?\s*[:,\-]?\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (namedListMatch != null) {
      final listTitle = _cleanListTitle(namedListMatch.group(1)!);
      final items = parseItems(namedListMatch.group(2)!);
      if (listTitle.isNotEmpty && items.isNotEmpty) {
        return HavenAiShoppingCommand(
          itemName: items.first.itemName,
          quantity: items.first.quantity,
          listTitle: listTitle,
          items: items,
        );
      }
    }
    if ((lower.startsWith('add ') || lower.startsWith('put ')) &&
        !mentionsShopping) {
      return null;
    }

    final match = RegExp(
      r'^(?:please\s+)?(?:add|put|buy|get)\s+(.+?)(?:\s+(?:to|on|in)\s+(?:my\s+)?(.+?))?$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null && mentionsShopping) {
      final itemText = text
          .replaceFirst(
            RegExp(
              r'^(?:please\s+)?(?:create|make|start)?\s*(?:a\s+)?(?:shopping|grocery|groceries)?\s*list\s*[:,\-]?\s*',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      final items = parseItems(itemText);
      if (items.isEmpty) return null;
      return HavenAiShoppingCommand(
        itemName: items.first.itemName,
        quantity: items.first.quantity,
        listTitle: 'Shopping list',
        items: items,
      );
    }
    if (match == null) return null;

    var itemText = match.group(1)!.trim();
    final destination = match.group(2)?.trim();
    if (destination != null &&
        !destination.toLowerCase().contains('shopping') &&
        !destination.toLowerCase().contains('grocery') &&
        !destination.toLowerCase().contains('list')) {
      return null;
    }

    itemText = itemText
        .replaceAll(
          RegExp(r'\b(shopping|grocery|list)\b', caseSensitive: false),
          '',
        )
        .trim();
    if (itemText.isEmpty) return null;

    final items = parseItems(itemText);
    if (items.length > 1) {
      return HavenAiShoppingCommand(
        itemName: items.first.itemName,
        quantity: items.first.quantity,
        listTitle: _listTitleFor(destination),
        items: items,
      );
    }

    final quantityMatch = RegExp(
      r'\b(\d+(?:[./]\d+)?\s*(?:ct|gal|g|kg|ml|l|litres?|liters?|litre|liter|ltr|ltre|lt|lbs?|packs?|bottles?|loaves?|bags?|pieces?|pcs?)?|litres?|liters?|litre|liter|ltr|ltre|kg|g|packs?|bottles?|loaves?|bags?|one|two|three|four|five|six|seven|eight|nine|ten)(?:\s+of\s+them)?$',
      caseSensitive: false,
    ).firstMatch(itemText);
    final quantity = quantityMatch?.group(1)?.trim() ?? '';
    if (quantity.isNotEmpty) {
      itemText = itemText.substring(0, quantityMatch!.start).trim();
    }

    return HavenAiShoppingCommand(
      itemName: _capitalize(itemText),
      quantity: quantity,
      listTitle: _listTitleFor(destination),
    );
  }

  static List<HavenAiShoppingItem> parseItems(String input) {
    var text = input
        .replaceAll(RegExp(r'\.\s+(?=[A-Za-z])'), ', ')
        .replaceAll(
          RegExp(
            r'\b(shopping|grocery|groceries|list)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\band\s+', caseSensitive: false), ', ')
        .trim();
    text = text.replaceAll(RegExp(r'^[:,\s]+|[:,\s]+$'), '');
    if (text.isEmpty) return const [];

    return text
        .split(RegExp(r'\s*[,;\n]\s*'))
        .map(_parseItemChunk)
        .whereType<HavenAiShoppingItem>()
        .toList(growable: false);
  }

  static HavenAiShoppingItem? _parseItemChunk(String chunk) {
    var text = chunk.trim();
    if (text.isEmpty) return null;
    text = text.replaceFirst(
      RegExp(r'^(add|buy|get|pick up|put)\s+', caseSensitive: false),
      '',
    );

    final lower = text.toLowerCase().trim();
    if (RegExp(
      r'^(?:named|called|titled|with\s+(?:these|this|the)\s+items?)$',
    ).hasMatch(lower)) {
      return null;
    }

    final quantityMatch = RegExp(
      r'(?:\s+|-)(\d+(?:[./]\d+)?\s*(?:ct|gal|g|kg|ml|l|litres?|liters?|litre|liter|ltr|ltre|lt|lbs?|packs?|bottles?|loaves?|bags?|pieces?|pcs?)?|litres?|liters?|litre|liter|ltr|ltre|kg|g|packs?|bottles?|loaves?|bags?|one|two|three|four|five|six|seven|eight|nine|ten)(?:\s+of\s+them)?$',
      caseSensitive: false,
    ).firstMatch(text);
    var quantity = quantityMatch?.group(1)?.trim() ?? '';
    if (quantity.isNotEmpty) {
      text = text.substring(0, quantityMatch!.start).trim();
    }

    if (quantity.isEmpty) {
      final embeddedQuantity = RegExp(
        r'\b(\d+(?:[./]\d+)?\s*(?:g|kg|mg|ml|l|litres?|liters?|litre|liter|ltr|ltre|lt|lbs?))\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(text);
      if (embeddedQuantity != null && embeddedQuantity.start > 0) {
        quantity = embeddedQuantity.group(1)!.trim();
        text =
            '${text.substring(0, embeddedQuantity.start).trim()} '
            '${embeddedQuantity.group(2)!.trim()}';
      }
    }

    final leadingQuantity = RegExp(
      r'^(\d+(?:[./]\d+)?\s*(?:ct|gal|g|kg|ml|l|litres?|liters?|litre|liter|ltr|ltre|lt|lbs?|packs?|bottles?|loaves?|bags?|pieces?|pcs?)?)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (leadingQuantity != null) {
      quantity = leadingQuantity.group(1)!.trim();
      text = leadingQuantity.group(2)!.trim();
    }

    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return null;
    return HavenAiShoppingItem(itemName: _capitalize(text), quantity: quantity);
  }

  static String? _listTitleFor(String? destination) {
    if (destination == null) return null;
    final lower = destination.toLowerCase();
    if (lower.contains('breakfast')) return 'Morning breakfast';
    if (lower.contains('shopping') || lower.contains('grocery')) {
      return 'Shopping list';
    }
    return null;
  }

  static String _cleanListTitle(String input) {
    return input
        .replaceAll(RegExp(r'^[,:;\-\s]+|[,:;\-\s]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

class HavenAiShoppingItem {
  const HavenAiShoppingItem({required this.itemName, this.quantity = ''});

  final String itemName;
  final String quantity;
}
