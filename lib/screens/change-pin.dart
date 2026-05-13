import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fjkm_kajy/services/security_service.dart';

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  String oldPin = "";
  String newPin = "";
  String confirmPin = "";

  int step = 0; // 0 = old, 1 = new, 2 = confirm

  void _onKeyPress(String value) async {
    if (step == 0 && oldPin.length < 4) {
      setState(() => oldPin += value);

      if (oldPin.length == 4) {
        bool ok = await PinService.verifyPin(oldPin);

        if (ok) {
          setState(() => step = 1);
        } else {
          HapticFeedback.heavyImpact();
          setState(() => oldPin = "");
          _showError("Ancien PIN incorrect");
        }
      }
    }

    else if (step == 1 && newPin.length < 4) {
      setState(() => newPin += value);

      if (newPin.length == 4) {
        setState(() => step = 2);
      }
    }

    else if (step == 2 && confirmPin.length < 4) {
      setState(() => confirmPin += value);

      if (confirmPin.length == 4) {
        _validate();
      }
    }
  }

  void _validate() async {
    if (newPin == confirmPin) {
      await PinService.savePin(newPin);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ PIN modifié")),
      );

      Navigator.pop(context);
    } else {
      HapticFeedback.heavyImpact();

      setState(() {
        newPin = "";
        confirmPin = "";
        step = 1;
      });

      _showError("PIN non identique");
    }
  }

  void _delete() {
    setState(() {
      if (step == 0 && oldPin.isNotEmpty) {
        oldPin = oldPin.substring(0, oldPin.length - 1);
      } else if (step == 1 && newPin.isNotEmpty) {
        newPin = newPin.substring(0, newPin.length - 1);
      } else if (step == 2 && confirmPin.isNotEmpty) {
        confirmPin = confirmPin.substring(0, confirmPin.length - 1);
      }
    });
  }

  String get currentPin {
    if (step == 0) return oldPin;
    if (step == 1) return newPin;
    return confirmPin;
  }

  String get title {
    if (step == 0) return "Entrer ancien PIN";
    if (step == 1) return "Nouveau PIN";
    return "Confirmer PIN";
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.all(8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: i < currentPin.length ? Colors.white : Colors.white24,
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
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        alignment: Alignment.center,
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier PIN"),
        backgroundColor: Colors.indigo,
      ),
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
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),

            const SizedBox(height: 20),
            _buildDots(),

            const SizedBox(height: 40),

            GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
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
          ],
        ),
      ),
    );
  }
}