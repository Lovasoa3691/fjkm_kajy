import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fjkm_kajy/services/security_service.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  String input = "";

  void _onKeyPress(String value) async {
    if (input.length >= 4) return;

    setState(() => input += value);

    if (input.length == 4) {
      await Future.delayed(const Duration(milliseconds: 200));

      bool ok = await PinService.verifyPin(input);

      if (ok) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        HapticFeedback.heavyImpact();

        setState(() => input = "");

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("PIN incorrect")));
      }
    }
  }

  void _delete() {
    if (input.isNotEmpty) {
      setState(() => input = input.substring(0, input.length - 1));
    }
  }

  Widget _buildDot(int index) {
    bool filled = index < input.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(8),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white24,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildKey(String value) {
    return GestureDetector(
      onTap: () => _onKeyPress(value),
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              Column(
                children: [
                  const Icon(Icons.lock, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  const Text(
                    "Entrer votre PIN",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, _buildDot),
                  ),
                ],
              ),

              GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox();
                  if (index == 10) return _buildKey("0");

                  if (index == 11) {
                    return GestureDetector(
                      onTap: _delete,
                      child: const Icon(Icons.backspace, color: Colors.white),
                    );
                  }

                  return _buildKey("${index + 1}");
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
