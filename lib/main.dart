import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Dock(
            itemsLabels: const ["Person", "Message", "Call", "Camera", "Photo"],
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (icon, label, isHovered) {
              return AnimatedIconWidget(
                icon: icon,
                label: label,
                isHovered: isHovered,
              );
            },
          ),
        ),
      ),
    );
  }
}

class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    required this.items,
    required this.itemsLabels,
    required this.builder,
  });

  final List<T> items;
  final List<String> itemsLabels;
  final Widget Function(T, String, bool) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T> extends State<Dock<T>> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  late List<T> _items;
  late List<String> _itemsLabels;

  @override
  void initState() {
    super.initState();
    _items = widget.items.toList();
    _itemsLabels = widget.itemsLabels.toList();
  }

  void onDragCompleted(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex != oldIndex) {
        // Update the items list
        final item = _items.removeAt(oldIndex);
        _items.insert(newIndex, item);

        // Update the labels list
        final label = _itemsLabels.removeAt(oldIndex);
        _itemsLabels.insert(newIndex, label);

        // update animated list
        _listKey.currentState!.insertItem(newIndex);
        _listKey.currentState!.removeItem(
          oldIndex,
          (context, animation) {
            return const SizedBox();
          },
        );
      }
    });
  }

  final RxInt hoveredIndex = (-1).obs;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black12,
      ),
      child: SizedBox(
        height: 70,
        child: AnimatedList(
          shrinkWrap: true,
          key: _listKey,
          scrollDirection: Axis.horizontal,
          initialItemCount: _items.length,
          itemBuilder: (context, index, animation) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
                    .chain(
                  CurveTween(curve: Curves.easeInOut),
                ),
              ),
              child: DraggableItem<T>(
                item: _items[index],
                index: index,
                builder: widget.builder,
                onDragCompleted: onDragCompleted,
                label: _itemsLabels[index],
                hoveredIndex: hoveredIndex,
              ),
            );
          },
        ),
      ),
    );
  }
}

class DraggableItem<T> extends StatelessWidget {
  final T item;
  final int index;
  final Widget Function(T, String, bool) builder;
  final Function(int, int) onDragCompleted;
  final String label;
  final RxInt hoveredIndex; // Global hovered index

  const DraggableItem({
    super.key,
    required this.item,
    required this.index,
    required this.builder,
    required this.onDragCompleted,
    required this.label,
    required this.hoveredIndex,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => hoveredIndex.value = index,
      onExit: (_) => hoveredIndex.value = -1,
      child: Draggable<int>(
        data: index,
        feedback: builder(item, label, true),
        childWhenDragging: const ChildWhenDragging(),
        onDragCompleted: () => onDragCompleted(index, index),
        child: DragTarget<int>(
          onAcceptWithDetails: (DragTargetDetails<int> details) {
            onDragCompleted(details.data, index);
          },
          builder: (context, candidateData, rejectedData) {
            return Obx(() {
              int distance = (hoveredIndex.value - index).abs();
              double alignmentY = 0.0;

              // Apply different alignment shifts based on distance
              if (distance == 0) {
                alignmentY = -1.0; // Main hovered item
              } else if (distance == 1) {
                alignmentY = -0.7; // Adjacent items
              } else if (distance == 2) {
                alignmentY = -0.35; // Second adjacent items
              }

              bool isHovering =
                  candidateData.isNotEmpty; // Check if an item is hovering

              return Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: distance == 0 ? 13 : 10),
                child: AnimatedContainer(
                  curve: Curves.decelerate,
                  duration: const Duration(milliseconds: 150),
                  alignment:
                      Alignment(0, hoveredIndex.value == -1 ? 0 : alignmentY),
                  child: Stack(
                    children: [builder(item, label, distance == 0)],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

class ChildWhenDragging extends StatefulWidget {
  const ChildWhenDragging({
    super.key,
  });

  @override
  State<ChildWhenDragging> createState() => _ChildWhenDraggingState();
}

class _ChildWhenDraggingState extends State<ChildWhenDragging> {
  RxDouble containerWidth = 76.0.obs;
  @override
  void initState() {
    containerWidth.value = 76;
    Future.delayed(const Duration(milliseconds: 10)).then(
      (value) {
        containerWidth.value = 0.0;
        setState(() {});
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        curve: Curves.decelerate,
        width: containerWidth.value,
        duration: const Duration(milliseconds: 500),
        child: const SizedBox());
  }
}

class AnimatedIconWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHovered; // Hover state passed in

  const AnimatedIconWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      preferBelow: false,
      excludeFromSemantics: true,
      padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 15),
      margin: const EdgeInsets.only(bottom: 20),
      textStyle: const TextStyle(color: Colors.white),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: const Color.fromARGB(221, 165, 114, 114).withOpacity(0.4)),
      message: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(isHovered ? 14 : 10), // Enlarge on hover
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.primaries[icon.hashCode % Colors.primaries.length],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
