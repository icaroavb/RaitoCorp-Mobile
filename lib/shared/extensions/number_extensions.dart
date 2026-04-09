import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
  decimalDigits: 0,
);

final _currencyFormatterWithCents = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
  decimalDigits: 2,
);

extension NumberCurrency on num {
  String formatCurrency({bool withCents = false}) {
    if (withCents || (this % 1 != 0)) {
      return _currencyFormatterWithCents.format(this);
    }
    return _currencyFormatter.format(this);
  }
}
