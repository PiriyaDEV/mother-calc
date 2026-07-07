// Shared constants used across create_bill_screen.dart, create_group_screen.dart,
// and home_screen.dart.

const kEmojiPresets = [
  '🍜', '🍕', '🍺', '🎉', '✈️', '🏖️', '🎂', '🛒',
  '🏠', '💊', '🎮', '🎵', '🚗', '⚽', '📚', '💼',
  '🌮', '🍣', '🥗', '🍔', '🍦', '☕', '🍷', '🎁',
  '🏋️', '🎬', '🛫', '🏕️', '🎯', '💰',
];

const kDefaultTags = [
  'อาหาร', 'เที่ยว', 'ปาร์ตี้', 'ช้อปปิ้ง', 'ที่พัก',
  'เดินทาง', 'บันเทิง', 'สุขภาพ', 'การศึกษา', 'อื่นๆ',
];

// ── Rounding (bill form) ──────────────────────────────────────────────────────

const kRoundingOptions = [
  {'value': 'none',    'label': 'ไม่ปัด'},
  {'value': 'nearest', 'label': 'ใกล้สุด'},
  {'value': 'up',      'label': 'ขึ้น'},
  {'value': 'down',    'label': 'ลง'},
];

// ── Currency ──────────────────────────────────────────────────────────────────
// Shared currency data used by create_bill_screen.dart (bill form picker)
// and home_screen.dart (exchange-rate cards).

class CurrencyConfig {
  final String code;
  final String flag;
  final String symbol;
  final String label; // short display name / Thai name
  const CurrencyConfig({
    required this.code,
    required this.flag,
    required this.symbol,
    required this.label,
  });
}

/// Full list of supported currencies (THB first, then sorted by popularity).
const kCurrencies = [
  CurrencyConfig(code: 'THB', flag: '🇹🇭', symbol: '฿',   label: 'บาท'),
  CurrencyConfig(code: 'USD', flag: '🇺🇸', symbol: '\$',  label: 'ดอลลาร์สหรัฐ'),
  CurrencyConfig(code: 'EUR', flag: '🇪🇺', symbol: '€',   label: 'ยูโร'),
  CurrencyConfig(code: 'JPY', flag: '🇯🇵', symbol: '¥',   label: 'เยนญี่ปุ่น'),
  CurrencyConfig(code: 'CNY', flag: '🇨🇳', symbol: '¥',   label: 'หยวนจีน'),
  CurrencyConfig(code: 'GBP', flag: '🇬🇧', symbol: '£',   label: 'ปอนด์อังกฤษ'),
  CurrencyConfig(code: 'KRW', flag: '🇰🇷', symbol: '₩',   label: 'วอนเกาหลี'),
  CurrencyConfig(code: 'SGD', flag: '🇸🇬', symbol: 'S\$', label: 'ดอลลาร์สิงคโปร์'),
  CurrencyConfig(code: 'AUD', flag: '🇦🇺', symbol: 'A\$', label: 'ดอลลาร์ออสเตรเลีย'),
  CurrencyConfig(code: 'HKD', flag: '🇭🇰', symbol: 'HK\$',label: 'ดอลลาร์ฮ่องกง'),
  CurrencyConfig(code: 'MYR', flag: '🇲🇾', symbol: 'RM',  label: 'ริงกิตมาเลเซีย'),
];

/// Subset shown in the bill-form currency picker (excludes less-common ones).
const kBillFormCurrencies = [
  CurrencyConfig(code: 'THB', flag: '🇹🇭', symbol: '฿',   label: 'บาท'),
  CurrencyConfig(code: 'USD', flag: '🇺🇸', symbol: '\$',  label: 'USD'),
  CurrencyConfig(code: 'EUR', flag: '🇪🇺', symbol: '€',   label: 'EUR'),
  CurrencyConfig(code: 'JPY', flag: '🇯🇵', symbol: '¥',   label: 'JPY'),
  CurrencyConfig(code: 'SGD', flag: '🇸🇬', symbol: 'S\$', label: 'SGD'),
  CurrencyConfig(code: 'GBP', flag: '🇬🇧', symbol: '£',   label: 'GBP'),
  CurrencyConfig(code: 'CNY', flag: '🇨🇳', symbol: '¥',   label: 'CNY'),
  CurrencyConfig(code: 'KRW', flag: '🇰🇷', symbol: '₩',   label: 'KRW'),
];

/// Exchange-rate display currencies (excludes THB since it's the base).
const kExchangeRateCurrencies = [
  CurrencyConfig(code: 'USD', flag: '🇺🇸', symbol: '\$',  label: 'ดอลลาร์สหรัฐ'),
  CurrencyConfig(code: 'EUR', flag: '🇪🇺', symbol: '€',   label: 'ยูโร'),
  CurrencyConfig(code: 'JPY', flag: '🇯🇵', symbol: '¥',   label: 'เยนญี่ปุ่น'),
  CurrencyConfig(code: 'CNY', flag: '🇨🇳', symbol: '¥',   label: 'หยวนจีน'),
  CurrencyConfig(code: 'GBP', flag: '🇬🇧', symbol: '£',   label: 'ปอนด์อังกฤษ'),
  CurrencyConfig(code: 'KRW', flag: '🇰🇷', symbol: '₩',   label: 'วอนเกาหลี'),
  CurrencyConfig(code: 'SGD', flag: '🇸🇬', symbol: 'S\$', label: 'ดอลลาร์สิงคโปร์'),
  CurrencyConfig(code: 'AUD', flag: '🇦🇺', symbol: 'A\$', label: 'ดอลลาร์ออสเตรเลีย'),
  CurrencyConfig(code: 'HKD', flag: '🇭🇰', symbol: 'HK\$',label: 'ดอลลาร์ฮ่องกง'),
  CurrencyConfig(code: 'MYR', flag: '🇲🇾', symbol: 'RM',  label: 'ริงกิตมาเลเซีย'),
];
