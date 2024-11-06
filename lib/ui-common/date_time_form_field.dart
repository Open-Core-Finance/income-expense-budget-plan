import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DateTimeFormField extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime)? onDateSelected;
  final Function(TimeOfDay)? onTimeSelected;
  final String dateFormat = "yyyy-MM-dd";

  const DateTimeFormField({
    super.key,
    this.initialDate,
    this.initialTime,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.onTimeSelected,
  });

  @override
  State<DateTimeFormField> createState() => _DateTimeFormFieldState();
}

class _DateTimeFormFieldState extends State<DateTimeFormField> {
  late TextEditingController _dateController;
  late TextEditingController _timeController;

  late DateTime _initialDate;
  late TimeOfDay _initialTime;
  late DateTime _firstDate;
  late DateTime _lastDate;

  @override
  void initState() {
    super.initState();
    final currentDate = DateTime.now();
    if (widget.initialDate != null) {
      _initialDate = widget.initialDate!;
    } else {
      _initialDate = currentDate;
    }
    if (widget.initialTime != null) {
      _initialTime = widget.initialTime!;
    } else {
      _initialTime = TimeOfDay.now();
    }
    if (widget.firstDate != null) {
      _firstDate = widget.firstDate!;
    } else {
      _firstDate = DateTime(DateTime.now().year - 60);
    }
    if (widget.lastDate != null) {
      _lastDate = widget.lastDate!;
    } else {
      _lastDate = DateTime(DateTime.now().year + 90);
    }
    _dateController = TextEditingController(text: DateFormat(widget.dateFormat).format(_initialDate));
    _timeController = TextEditingController(text: "");
    // Delay initialization of controllers until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timeController.text = MaterialLocalizations.of(context).formatTimeOfDay(_initialTime);
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _initialDate,
      firstDate: _firstDate,
      lastDate: _lastDate,
    );

    if (pickedDate != null) {
      _initialDate = pickedDate;
      setState(() {
        _dateController.text = DateFormat(widget.dateFormat).format(pickedDate);
      });
      if (widget.onDateSelected != null) {
        widget.onDateSelected!(pickedDate);
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _initialTime,
    );

    if (pickedTime != null) {
      _initialTime = pickedTime;
      setState(() {
        _timeController.text = MaterialLocalizations.of(context).formatTimeOfDay(pickedTime);
      });
      if (widget.onTimeSelected != null) {
        widget.onTimeSelected!(pickedTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: appLocalizations.date,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            onTap: () => _selectDate(context),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return appLocalizations.selectDateEmpty;
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _timeController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: appLocalizations.time,
              suffixIcon: const Icon(Icons.access_time),
            ),
            onTap: () => _selectTime(context),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return appLocalizations.time;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
