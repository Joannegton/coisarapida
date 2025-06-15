import 'package:flutter/material.dart';
import 'dart:async';

/// Widget que mostra contador regressivo até a data limite de devolução
class ContadorTempo extends StatefulWidget {
  final DateTime dataLimite;
  final VoidCallback? onAtraso;

  const ContadorTempo({
    super.key,
    required this.dataLimite,
    this.onAtraso,
  });

  @override
  State<ContadorTempo> createState() => _ContadorTempoState();
}

class _ContadorTempoState extends State<ContadorTempo> {
  Timer? _timer;
  Duration _tempoRestante = Duration.zero;
  bool _emAtraso = false;

  @override
  void initState() {
    super.initState();
    _calcularTempoRestante();
    _iniciarTimer();
  }

  void _calcularTempoRestante() {
    final agora = DateTime.now();
    final diferenca = widget.dataLimite.difference(agora);
    
    setState(() {
      if (diferenca.isNegative) {
        _emAtraso = true;
        _tempoRestante = agora.difference(widget.dataLimite);
        widget.onAtraso?.call();
      } else {
        _emAtraso = false;
        _tempoRestante = diferenca;
      }
    });
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calcularTempoRestante();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _emAtraso ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _emAtraso ? Colors.red[300]! : Colors.blue[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _emAtraso ? Icons.timer_off : Icons.timer,
            size: 32,
            color: _emAtraso ? Colors.red[600] : Colors.blue[600],
          ),
          const SizedBox(height: 8),
          
          Text(
            _emAtraso ? 'TEMPO EM ATRASO' : 'TEMPO RESTANTE',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _emAtraso ? Colors.red[700] : Colors.blue[700],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Contador
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTempoBox('${_tempoRestante.inDays}', 'Dias'),
              const SizedBox(width: 8),
              _buildTempoBox('${_tempoRestante.inHours % 24}', 'Horas'),
              const SizedBox(width: 8),
              _buildTempoBox('${_tempoRestante.inMinutes % 60}', 'Min'),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _emAtraso 
                ? 'Devolva o item imediatamente!'
                : 'Até ${_formatarDataLimite()}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _emAtraso ? Colors.red[600] : Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTempoBox(String valor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _emAtraso ? Colors.red[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _emAtraso ? Colors.red[700] : Colors.blue[700],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _emAtraso ? Colors.red[600] : Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarDataLimite() {
    return '${widget.dataLimite.day.toString().padLeft(2, '0')}/${widget.dataLimite.month.toString().padLeft(2, '0')} às ${widget.dataLimite.hour.toString().padLeft(2, '0')}:${widget.dataLimite.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
