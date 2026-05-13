import 'package:flutter/material.dart';
import 'package:fjkm_kajy/services/security_service.dart';
import 'package:flutter/services.dart';

class SetupPinPage extends StatefulWidget {
  const SetupPinPage({super.key});

  @override
  State<SetupPinPage> createState() => _SetupPinPageState();
}

class _SetupPinPageState extends State<SetupPinPage> {
  String firstPin = "";
  String confirmPin = "";
  bool isConfirming = false;

  void _onKeyPress(String value) {
    if (!isConfirming) {
      if (firstPin.length < 4) {
        setState(() => firstPin += value);

        if (firstPin.length == 4) {
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() => isConfirming = true);
          });
        }
      }
    } else {
      if (confirmPin.length < 4) {
        setState(() => confirmPin += value);

        if (confirmPin.length == 4) {
          _validate();
        }
      }
    }
  }

  void _validate() async {
    if (firstPin == confirmPin) {
      await PinService.savePin(firstPin);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      HapticFeedback.heavyImpact();

      setState(() {
        firstPin = "";
        confirmPin = "";
        isConfirming = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("PIN non identique")));
    }
  }

  Widget _buildDots(String pin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.all(8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: i < pin.length ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
          ),
        );
      }),
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
    final currentPin = isConfirming ? confirmPin : firstPin;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isConfirming ? "Confirmer PIN" : "Créer un PIN",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),

            const SizedBox(height: 20),
            _buildDots(currentPin),

            const SizedBox(height: 40),

            GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox();
                if (index == 10) return _buildKey("0");

                if (index == 11) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isConfirming && confirmPin.isNotEmpty) {
                          confirmPin = confirmPin.substring(
                            0,
                            confirmPin.length - 1,
                          );
                        } else if (!isConfirming && firstPin.isNotEmpty) {
                          firstPin = firstPin.substring(0, firstPin.length - 1);
                        }
                      });
                    },
                    child: const Icon(Icons.backspace, color: Colors.white),
                  );
                }

                return _buildKey("${index + 1}");
              },
            ),
          ],
        ),
      ),
    );
  }
}
