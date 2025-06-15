import 'package:flutter/material.dart';

/// Widget para seleção de datas de aluguel
class SeletorDatas extends StatefulWidget {
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final Function(DateTime?, DateTime?) onDatasChanged;
  final double? precoPorDia;
  final double? precoPorHora;
  final bool permitirPorHora;

  const SeletorDatas({
    super.key,
    this.dataInicio,
    this.dataFim,
    required this.onDatasChanged,
    this.precoPorDia,
    this.precoPorHora,
    this.permitirPorHora = false,
  });

  @override
  State<SeletorDatas> createState() => _SeletorDatasState();
}

class _SeletorDatasState extends State<SeletorDatas> {
  DateTime? _dataInicio;
  DateTime? _dataFim;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  bool _aluguelPorHora = false;

  @override
  void initState() {
    super.initState();
    _dataInicio = widget.dataInicio;
    _dataFim = widget.dataFim;
    _horaInicio = const TimeOfDay(hour: 9, minute: 0);
    _horaFim = const TimeOfDay(hour: 18, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selecionar Período',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Tipo de aluguel
          if (widget.permitirPorHora) ...[
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Por dias'),
                    value: false,
                    groupValue: _aluguelPorHora,
                    onChanged: (value) {
                      setState(() => _aluguelPorHora = value!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Por horas'),
                    value: true,
                    groupValue: _aluguelPorHora,
                    onChanged: (value) {
                      setState(() => _aluguelPorHora = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Seleção de datas
          Row(
            children: [
              Expanded(
                child: _buildSeletorData(
                  'Data de início',
                  _dataInicio,
                  (data) {
                    setState(() {
                      _dataInicio = data;
                      if (_dataFim != null && data != null && data.isAfter(_dataFim!)) {
                        _dataFim = null;
                      }
                    });
                    _atualizarDatas();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSeletorData(
                  'Data de fim',
                  _dataFim,
                  (data) {
                    setState(() => _dataFim = data);
                    _atualizarDatas();
                  },
                  dataMinima: _dataInicio,
                ),
              ),
            ],
          ),
          
          // Seleção de horários (se por hora)
          if (_aluguelPorHora && _dataInicio != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSeletorHora(
                    'Hora de início',
                    _horaInicio!,
                    (hora) {
                      setState(() => _horaInicio = hora);
                      _atualizarDatas();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSeletorHora(
                    'Hora de fim',
                    _horaFim!,
                    (hora) {
                      setState(() => _horaFim = hora);
                      _atualizarDatas();
                    },
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Resumo do período
          if (_dataInicio != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do Período',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_obterResumoPeriodo()),
                  const SizedBox(height: 8),
                  Text(
                    'Valor total: ${_calcularValorTotal()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _dataInicio != null ? _confirmarDatas : null,
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorData(
    String label,
    DateTime? data,
    Function(DateTime?) onChanged, {
    DateTime? dataMinima,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selecionarData(onChanged, dataMinima),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  data != null 
                      ? _formatarData(data)
                      : 'Selecionar',
                  style: TextStyle(
                    color: data != null ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeletorHora(
    String label,
    TimeOfDay hora,
    Function(TimeOfDay) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selecionarHora(hora, onChanged),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(_formatarHora(hora)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _selecionarData(Function(DateTime?) onChanged, DateTime? dataMinima) async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: dataMinima ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    
    if (data != null) {
      onChanged(data);
    }
  }

  void _selecionarHora(TimeOfDay horaAtual, Function(TimeOfDay) onChanged) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: horaAtual,
    );
    
    if (hora != null) {
      onChanged(hora);
    }
  }

  void _atualizarDatas() {
    DateTime? inicio = _dataInicio;
    DateTime? fim = _dataFim;
    
    if (_aluguelPorHora && inicio != null && _horaInicio != null) {
      inicio = DateTime(
        inicio.year,
        inicio.month,
        inicio.day,
        _horaInicio!.hour,
        _horaInicio!.minute,
      );
      
      if (fim != null && _horaFim != null) {
        fim = DateTime(
          fim.year,
          fim.month,
          fim.day,
          _horaFim!.hour,
          _horaFim!.minute,
        );
      }
    }
    
    widget.onDatasChanged(inicio, fim);
  }

  void _confirmarDatas() {
    _atualizarDatas();
    Navigator.of(context).pop();
  }

  String _obterResumoPeriodo() {
    if (_dataInicio == null) return '';
    
    if (_aluguelPorHora) {
      if (_dataFim != null) {
        final duracao = _dataFim!.difference(_dataInicio!);
        final horas = duracao.inHours;
        final minutos = duracao.inMinutes % 60;
        return 'Duração: ${horas}h${minutos > 0 ? ' ${minutos}min' : ''}';
      } else {
        return 'De ${_formatarData(_dataInicio!)} às ${_formatarHora(_horaInicio!)}';
      }
    } else {
      if (_dataFim != null) {
        final dias = _dataFim!.difference(_dataInicio!).inDays + 1;
        return 'Período: $dias dia${dias > 1 ? 's' : ''}';
      } else {
        return 'A partir de ${_formatarData(_dataInicio!)}';
      }
    }
  }

  String _calcularValorTotal() {
    if (_dataInicio == null) return 'R\$ 0,00';
    
    if (_aluguelPorHora && _dataFim != null && widget.precoPorHora != null) {
      final duracao = _dataFim!.difference(_dataInicio!);
      final horas = duracao.inHours;
      final valor = horas * widget.precoPorHora!;
      return 'R\$ ${valor.toStringAsFixed(2)}';
    } else if (!_aluguelPorHora && _dataFim != null && widget.precoPorDia != null) {
      final dias = _dataFim!.difference(_dataInicio!).inDays + 1;
      final valor = dias * widget.precoPorDia!;
      return 'R\$ ${valor.toStringAsFixed(2)}';
    }
    
    return 'R\$ 0,00';
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }
}
