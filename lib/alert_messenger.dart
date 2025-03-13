import 'package:flutter/material.dart';

const kAlertHeight = 80.0;

enum AlertPriority {
  error(2),
  warning(1),
  info(0);

  const AlertPriority(this.value);
  final int value;
}

class Alert extends StatelessWidget {
  const Alert({
    super.key,
    required this.backgroundColor,
    required this.child,
    required this.leading,
    required this.priority,
  });

  final Color backgroundColor;
  final Widget child;
  final Widget leading;
  final AlertPriority priority;

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;
    return Material(
      child: Ink(
        color: backgroundColor,
        height: kAlertHeight + statusbarHeight,
        child: Column(
          children: [
            SizedBox(height: statusbarHeight),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 28.0),
                  IconTheme(
                    data: const IconThemeData(
                      color: Colors.white,
                      size: 36,
                    ),
                    child: leading,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28.0),
          ],
        ),
      ),
    );
  }
}

class AlertMessenger extends StatefulWidget {
  const AlertMessenger({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AlertMessenger> createState() => AlertMessengerState();

  static AlertMessengerState of(BuildContext context) {
    try {
      final scope = _AlertMessengerScope.of(context);
      return scope.state;
    } catch (error) {
      throw FlutterError.fromParts(
        [
          ErrorSummary('No AlertMessenger was found in the Element tree'),
          ErrorDescription('AlertMessenger is required in order to show and hide alerts.'),
          ...context.describeMissingAncestor(expectedAncestorType: AlertMessenger),
        ],
      );
    }
  }
}

class AlertMessengerState extends State<AlertMessenger> with TickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  final List<Alert> alertQueue = [];
  final Map<Alert, AnimationController> alertControllers = {};
  String currentAlertMessage = "";

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    controller.dispose();
    for (var ac in alertControllers.values) {
      ac.dispose();
    }
    super.dispose();
  }

  void showAlert({required Alert alert}) {
    if (alertQueue.isNotEmpty && alertQueue.last.priority.value >= alert.priority.value) {
      return;
    }

    final newController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    setState(() {
      alertQueue.add(alert);
      alertControllers[alert] = newController;
      currentAlertMessage = (alert.child as Text).data ?? "";
    });
    newController.forward();
  }

  void hideAlert() {
    if (alertQueue.isEmpty) return;

    final currentAlert = alertQueue.last;
    final currentController = alertControllers[currentAlert];
    
    currentController?.reverse().then((_) {
      setState(() {
        alertQueue.remove(currentAlert);
        alertControllers.remove(currentAlert);
        currentAlertMessage = alertQueue.isNotEmpty ? (alertQueue.last.child as Text).data ?? "" : "";
      });
    });
  }

  static String getCurrentAlertMessage(BuildContext context) {
    final state = _AlertMessengerScope.of(context).state;
    return state.currentAlertMessage;
  }

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;

    return _AlertMessengerScope(
      state: this,
      child: Stack(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        children: [
          Positioned.fill(
            top: 0,
            child: widget.child,
          ),
          // Display all alerts in the queue with animations
          ...alertQueue.asMap().entries.map((entry) {
            final index = entry.key;
            final alert = entry.value;
            final alertAnimation = alertControllers[alert]?.drive(
              Tween<double>(begin: -kAlertHeight, end: index * kAlertHeight * 0.8),
            );
            
            return AnimatedBuilder(
              animation: alertAnimation ?? const AlwaysStoppedAnimation(0),
              builder: (context, child) {
                return Positioned(
                  top: (alertAnimation?.value ?? 0) + statusbarHeight,
                  left: 0,
                  right: 0,
                  child: alert,
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}


class _AlertMessengerScope extends InheritedWidget {
  const _AlertMessengerScope({
    required this.state,
    required super.child,
  });

  final AlertMessengerState state;

  @override
  bool updateShouldNotify(_AlertMessengerScope oldWidget) => state != oldWidget.state;

  static _AlertMessengerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AlertMessengerScope>();
  }

  static _AlertMessengerScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No _AlertMessengerScope found in context');
    return scope!;
  }
}
