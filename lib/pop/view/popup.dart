import 'package:flutter/material.dart';

import '../load.dart';

class Popup extends StatelessWidget {
  const Popup({super.key, required this.msg, this.onTap});

  final String msg;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.of(context).size.width * 0.9,
    height: 180,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white, width: 0.5),
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text("Tips", style: TextStyle(fontSize: 15)),
        const Spacer(),
        Text(msg, style: TextStyle(fontSize: 15)),
        const Spacer(),
        Divider(height: 0.5, color: Colors.grey.shade300),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Load.h.dismiss(),
                child: Text("Cancel", style: TextStyle(fontSize: 13)),
              ),
            ),
            Container(height: 15, width: 1, color: Colors.grey),
            Expanded(
              child: TextButton(onPressed: onTap, child: Text("Confirm", style: TextStyle(fontSize: 13))),
            ),
          ],
        ),
      ],
    ),
  );
}
