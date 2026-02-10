import 'package:flutter/material.dart';

class BenchmarkHandles {
  final ScrollController scrollController;
  final BuildContext context;
  final TickerProvider tickerProvider;

  BenchmarkHandles({
    required this.scrollController,
    required this.context,
    required this.tickerProvider,
  });
}
