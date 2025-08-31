import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:hijri/hijri_calendar.dart' as hijri;
import 'dart:math' as math;
import 'package:intl/intl.dart' as intl;

class PersianCalendarDialog extends StatefulWidget {
  final Jalali? initialDate;
  final Jalali firstDate;
  final Jalali lastDate;
  final Color? primaryColor;
  final Color? accentColor;
  final String? title;
  final String? confirmText;
  final String? cancelText;
  final bool showTodayButton;
  final bool showQuickSelectButtons;
  final bool showManualDateInput;
  final bool showOtherCalendars;
  final bool showGregorianDates;
  final bool showHijriDates;

  const PersianCalendarDialog({
    Key? key,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.primaryColor,
    this.accentColor,
    this.title,
    this.confirmText,
    this.cancelText,
    this.showTodayButton = true,
    this.showQuickSelectButtons = true,
    this.showManualDateInput = true,
    this.showOtherCalendars = true,
    this.showGregorianDates = true,
    this.showHijriDates = true,
  }) : super(key: key);

  @override
  PersianCalendarDialogState createState() => PersianCalendarDialogState();
}

class PersianCalendarDialogState extends State<PersianCalendarDialog>
    with TickerProviderStateMixin {
  late Jalali selectedDate;
  late int currentYear;
  late int currentMonth;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _monthChangeController;
  late Animation<double> _monthChangeAnimation;
  bool _isMonthChanging = false;
  int _direction = 0; // 0: no change, 1: forward, -1: backward

  // متغیرهای ورودی تاریخ دستی
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final FocusNode _dayFocusNode = FocusNode();
  final FocusNode _monthFocusNode = FocusNode();
  final FocusNode _yearFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? Jalali.now();
    currentYear = selectedDate.year;
    currentMonth = selectedDate.month;

    // تنظیم مقادیر اولیه فیلدهای ورودی تاریخ
    _dayController.text = selectedDate.day.toString();
    _monthController.text = selectedDate.month.toString();
    _yearController.text = selectedDate.year.toString();

    // انیمیشن ظاهر شدن تقویم
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();

    // انیمیشن تغییر ماه
    _monthChangeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _monthChangeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _monthChangeController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _monthChangeController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _dayFocusNode.dispose();
    _monthFocusNode.dispose();
    _yearFocusNode.dispose();
    super.dispose();
  }

  void _changeMonth(int direction) {
    if (_isMonthChanging) return;
    setState(() {
      _direction = direction;
      _isMonthChanging = true;
    });
    if (direction == 1) {
      // ماه بعد
      if (currentMonth == 12) {
        currentMonth = 1;
        currentYear++;
      } else {
        currentMonth++;
      }
    } else {
      // ماه قبل
      if (currentMonth == 1) {
        currentMonth = 12;
        currentYear--;
      } else {
        currentMonth--;
      }
    }
    _monthChangeController.forward().then((_) {
      setState(() {
        _isMonthChanging = false;
        _direction = 0;
      });
      _monthChangeController.reset();
    });
  }

  void _goToToday() {
    final today = Jalali.now();
    setState(() {
      selectedDate = today;
      currentYear = today.year;
      currentMonth = today.month;
      _updateDateInputs(today);
    });
  }

  void _updateDateInputs(Jalali date) {
    _dayController.text = date.day.toString();
    _monthController.text = date.month.toString();
    _yearController.text = date.year.toString();
  }

  void _selectQuickDate(Jalali date) {
    setState(() {
      selectedDate = date;
      currentYear = date.year;
      currentMonth = date.month;
      _updateDateInputs(date);
    });
  }

  void _submitManualDate() {
    if (_formKey.currentState!.validate()) {
      final day = int.parse(_dayController.text);
      final month = int.parse(_monthController.text);
      final year = int.parse(_yearController.text);

      try {
        final newDate = Jalali(year, month, day);
        final dateDateTime = newDate.toDateTime();
        final firstDateTime = widget.firstDate.toDateTime();
        final lastDateTime = widget.lastDate.toDateTime();

        if (dateDateTime.isBefore(firstDateTime) ||
            dateDateTime.isAfter(lastDateTime)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تاریخ وارد شده خارج از محدوده مجاز است'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          selectedDate = newDate;
          currentYear = year;
          currentMonth = month;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تاریخ وارد شده معتبر نیست'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final accentColor = widget.accentColor ?? theme.colorScheme.secondary;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title ?? 'انتخاب تاریخ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            if (widget.showTodayButton)
              TextButton(
                onPressed: _goToToday,
                child: Text(
                  'امروز',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        content: FadeTransition(
          opacity: _fadeAnimation,
          child: SizedBox(
            width: 340,
            height: widget.showManualDateInput ? 520 : 450,
            child: Column(
              children: [
                // هدر با انتخاب سال و ماه
                _buildHeader(primaryColor, accentColor),
                const SizedBox(height: 10),
                // روزهای هفته
                _buildWeekDays(primaryColor),
                const SizedBox(height: 5),
                // تقویم
                Expanded(
                  child: Stack(
                    children: [
                      _buildCalendar(primaryColor, accentColor, isDarkMode),
                      if (_isMonthChanging)
                        _buildMonthChangeAnimation(
                            primaryColor, accentColor, isDarkMode),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // نمایش سایر تقویم‌ها
                if (widget.showOtherCalendars)
                  _buildOtherCalendars(primaryColor, isDarkMode),
                const SizedBox(height: 10),
                // دکمه‌های انتخاب سریع
                if (widget.showQuickSelectButtons)
                  _buildQuickSelectButtons(primaryColor),
                const SizedBox(height: 10),
                // ورودی تاریخ دستی
                if (widget.showManualDateInput)
                  _buildManualDateInput(primaryColor),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              widget.cancelText ?? 'لغو',
              style: TextStyle(color: primaryColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, selectedDate),
            child: Text(widget.confirmText ?? 'تأیید'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // دکمه ماه قبل
          IconButton(
            icon: Icon(Icons.chevron_right, color: primaryColor),
            onPressed: () => _changeMonth(-1),
            splashRadius: 20,
          ),
          // انتخاب ماه
          Expanded(
            child: Center(
              child: DropdownButton<int>(
                value: currentMonth,
                isExpanded: true,
                underline: Container(),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                items: List.generate(12, (index) => index + 1)
                    .map((month) => DropdownMenuItem<int>(
                          value: month,
                          child: Center(
                            child: Text(
                              _getMonthName(month),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      currentMonth = value;
                    });
                  }
                },
              ),
            ),
          ),
          // انتخاب سال
          SizedBox(
            width: 80,
            child: DropdownButton<int>(
              value: currentYear,
              isExpanded: true,
              underline: Container(),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              items: List.generate(
                      widget.lastDate.year - widget.firstDate.year + 1,
                      (index) => widget.firstDate.year + index)
                  .map((year) => DropdownMenuItem<int>(
                        value: year,
                        child: Center(
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    currentYear = value;
                  });
                }
              },
            ),
          ),
          // دکمه ماه بعد
          IconButton(
            icon: Icon(Icons.chevron_left, color: primaryColor),
            onPressed: () => _changeMonth(1),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays(Color primaryColor) {
    return Row(
      children: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']
          .map(
            (day) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  border: day == 'ج'
                      ? Border.all(
                          color: primaryColor.withOpacity(0.5), width: 1)
                      : null,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendar(
      Color primaryColor, Color accentColor, bool isDarkMode) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: Jalali(currentYear, currentMonth, 1).monthLength,
      itemBuilder: (context, index) {
        final day = index + 1;
        final date = Jalali(currentYear, currentMonth, day);
        final isToday = Jalali.now() == date;
        final isSelected = selectedDate == date;

        // تبدیل تاریخ به میلادی برای مقایسه
        final dateDateTime = date.toDateTime();
        final firstDateTime = widget.firstDate.toDateTime();
        final lastDateTime = widget.lastDate.toDateTime();
        final isDisabled = dateDateTime.isBefore(firstDateTime) ||
            dateDateTime.isAfter(lastDateTime);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : isToday
                    ? primaryColor.withOpacity(0.2)
                    : null,
            shape: BoxShape.circle,
            border: isToday && !isSelected
                ? Border.all(color: primaryColor, width: 1.5)
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: isDisabled
                ? null
                : () {
                    setState(() {
                      selectedDate = date;
                      _updateDateInputs(date);
                    });
                  },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    color: isDisabled
                        ? Colors.grey
                        : isSelected
                            ? Colors.white
                            : (isDarkMode ? Colors.white : Colors.black),
                    fontWeight: isSelected || isToday ? FontWeight.bold : null,
                  ),
                ),
                if (isToday && !isSelected)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthChangeAnimation(
      Color primaryColor, Color accentColor, bool isDarkMode) {
    return AnimatedBuilder(
      animation: _monthChangeAnimation,
      builder: (context, child) {
        final slideValue = _direction * 300 * (1 - _monthChangeAnimation.value);
        final opacityValue = 1 - _monthChangeAnimation.value;
        return Transform.translate(
          offset: Offset(slideValue, 0),
          child: Opacity(
            opacity: opacityValue,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: Jalali(currentYear, currentMonth, 1).monthLength,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = Jalali(currentYear, currentMonth, day);
                final isToday = Jalali.now() == date;
                final isSelected = selectedDate == date;

                // تبدیل تاریخ به میلادی برای مقایسه
                final dateDateTime = date.toDateTime();
                final firstDateTime = widget.firstDate.toDateTime();
                final lastDateTime = widget.lastDate.toDateTime();
                final isDisabled = dateDateTime.isBefore(firstDateTime) ||
                    dateDateTime.isAfter(lastDateTime);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : isToday
                            ? primaryColor.withOpacity(0.2)
                            : null,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: primaryColor, width: 1.5)
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: isDisabled
                        ? null
                        : () {
                            setState(() {
                              selectedDate = date;
                              _updateDateInputs(date);
                            });
                          },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          day.toString(),
                          style: TextStyle(
                            color: isDisabled
                                ? Colors.grey
                                : isSelected
                                    ? Colors.white
                                    : (isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                            fontWeight:
                                isSelected || isToday ? FontWeight.bold : null,
                          ),
                        ),
                        if (isToday && !isSelected)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickSelectButtons(Color primaryColor) {
    final today = Jalali.now();
    final yesterday = today.addDays(-1);
    final lastWeek = today.addDays(-7);
    final lastMonth = today.addMonths(-1);
    final threeMonthsAgo = today.addMonths(-3);
    final sixMonthsAgo = today.addMonths(-6);
    final lastYear = today.addYears(-1);

    return Container(
      height: 35, // کاهش ارتفاع
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickSelectButton(
            text: 'دیروز',
            date: yesterday,
            onTap: _selectQuickDate,
            primaryColor: primaryColor,
          ),
          _QuickSelectButton(
            text: 'هفته',
            date: lastWeek,
            onTap: _selectQuickDate,
            primaryColor: primaryColor,
          ),
          _QuickSelectButton(
            text: 'ماه',
            date: lastMonth,
            onTap: _selectQuickDate,
            primaryColor: primaryColor,
          ),
          _QuickSelectButton(
            text: '۳ ماه',
            date: threeMonthsAgo,
            onTap: _selectQuickDate,
            primaryColor: primaryColor,
          ),
          _QuickSelectButton(
            text: '۶ ماه',
            date: sixMonthsAgo,
            onTap: _selectQuickDate,
            primaryColor: primaryColor,
          ),
          _QuickSelectButton(
            text: 'سال',
            date: lastYear,
            onTap: _selectQuickDate,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildOtherCalendars(Color primaryColor, bool isDarkMode) {
    final DateTime gregorianDate = selectedDate.toDateTime();
    final hijriDate = hijri.HijriCalendar.fromDate(gregorianDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.showGregorianDates)
                Text(
                  'میلادی: ${intl.DateFormat('yyyy/MM/dd').format(gregorianDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              if (widget.showHijriDates)
                Text(
                  'قمری: ${hijriDate.hYear}/${hijriDate.hMonth.toString().padLeft(2, '0')}/${hijriDate.hDay.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'شمسی: ${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualDateInput(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dayController,
                focusNode: _dayFocusNode,
                decoration: InputDecoration(
                  labelText: 'روز',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_monthFocusNode);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'روز را وارد کنید';
                  }
                  final day = int.tryParse(value);
                  if (day == null || day < 1 || day > 31) {
                    return 'روز معتبر نیست';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _monthController,
                focusNode: _monthFocusNode,
                decoration: InputDecoration(
                  labelText: 'ماه',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_yearFocusNode);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ماه را وارد کنید';
                  }
                  final month = int.tryParse(value);
                  if (month == null || month < 1 || month > 12) {
                    return 'ماه معتبر نیست';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _yearController,
                focusNode: _yearFocusNode,
                decoration: InputDecoration(
                  labelText: 'سال',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitManualDate(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'سال را وارد کنید';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 1300 || year > 1500) {
                    return 'سال معتبر نیست';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.check, color: primaryColor),
              onPressed: _submitManualDate,
              tooltip: 'تأیید تاریخ',
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند'
    ];
    return monthNames[month - 1];
  }
}

class _QuickSelectButton extends StatelessWidget {
  final String text;
  final Jalali date;
  final Function(Jalali) onTap;
  final Color primaryColor;

  const _QuickSelectButton({
    Key? key,
    required this.text,
    required this.date,
    required this.onTap,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor.withOpacity(0.1),
          foregroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 4), // کاهش padding
          minimumSize: const Size(30, 25), // کاهش حداقل اندازه
        ),
        onPressed: () => onTap(date),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10, // کاهش اندازه فونت
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// تابع برای نمایش دیالوگ تقویم شمسی
Future<Jalali?> showPersianCalendar({
  required BuildContext context,
  Jalali? initialDate,
  required Jalali firstDate,
  required Jalali lastDate,
  Color? primaryColor,
  Color? accentColor,
  String? title,
  String? confirmText,
  String? cancelText,
  bool showTodayButton = true,
  bool showQuickSelectButtons = true,
  bool showManualDateInput = true,
  bool showOtherCalendars = true,
  bool showGregorianDates = true,
  bool showHijriDates = true,
}) async {
  return await showDialog<Jalali>(
    context: context,
    builder: (context) => PersianCalendarDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      primaryColor: primaryColor,
      accentColor: accentColor,
      title: title,
      confirmText: confirmText,
      cancelText: cancelText,
      showTodayButton: showTodayButton,
      showQuickSelectButtons: showQuickSelectButtons,
      showManualDateInput: showManualDateInput,
      showOtherCalendars: showOtherCalendars,
      showGregorianDates: showGregorianDates,
      showHijriDates: showHijriDates,
    ),
  );
}

// اکستنشن برای افزودن قابلیت‌های ریاضی به کلاس Jalali
extension JalaliExtensions on Jalali {
  Jalali addDays(int days) {
    return copyWith(day: day + days);
  }

  Jalali addMonths(int months) {
    var newMonth = month + months;
    var newYear = year;
    if (newMonth > 12) {
      newYear += (newMonth - 1) ~/ 12;
      newMonth = (newMonth - 1) % 12 + 1;
    } else if (newMonth < 1) {
      newYear += newMonth ~/ 12;
      newMonth = newMonth % 12 + 12;
    }
    // اطمینان از اینکه روز در محدوده ماه جدید قرار دارد
    final maxDay = Jalali(newYear, newMonth, 1).monthLength;
    final newDay = math.min(day, maxDay);
    return Jalali(newYear, newMonth, newDay);
  }

  Jalali addYears(int years) {
    return copyWith(year: year + years);
  }

  Jalali copyWith({
    int? year,
    int? month,
    int? day,
  }) {
    return Jalali(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
    );
  }
}
