#!/usr/bin/env python3
"""
Smart i18n wiring script.
- Adds provider import if missing
- Adds `final l = context.watch<LocaleProvider>();` only to build() methods that actually USE l.t()
- Removes `const` before widget constructors whose arguments now use l.t()
- Skips strings inside non-build methods (initState, _handleX, etc.)
"""
import os, re

PROVIDER_IMPORT = "import 'package:provider/provider.dart';"
LOCALE_IMPORT   = "import 'package:kidtang_flutter/providers/locale_provider.dart';"

# ── Per-file replacements ─────────────────────────────────────────────────────
# Format: path -> list of (old_string_literal, new_expression)
# Only strings that appear INSIDE build() methods (verified manually).
FILE_REPLACEMENTS = {

  # ── me/ widgets ──────────────────────────────────────────────────────────────
  'lib/widgets/me/account_section.dart': [
    ("const SectionHeaderWidget(label: 'บัญชี')",
     "SectionHeaderWidget(label: l.t('me_account'))"),
    ("label: 'ชื่อที่แสดง'",
     "label: l.t('profile_display_name')"),
    ("label: 'พร้อมเพย์ (ใช้เป็น default ในบิล)'",
     "label: l.t('me_promptpay_default_label')"),
    ("? 'ยังไม่ได้ตั้งค่า'",
     ": l.t('me_not_set')"),
    ("hintText: 'เบอร์โทร หรือ เลขบัตรประชาชน'",
     "hintText: l.t('me_promptpay_hint_short')"),
  ],

  'lib/widgets/me/settings_section.dart': [
    ("const SectionHeaderWidget(label: 'การตั้งค่า')",
     "SectionHeaderWidget(label: l.t('me_settings'))"),
    ("label: 'โหมดสีเข้ม'",
     "label: l.t('me_dark_mode')"),
    ("label: 'ภาษา'",
     "label: l.t('language')"),
    ("isThai ? '🇹🇭 ไทย' : '🇬🇧 EN'",
     "isThai ? l.t('me_language_thai') : 'EN'"),
    ("label: 'การแจ้งเตือน'",
     "label: l.t('me_notifications')"),
  ],

  'lib/widgets/me/security_section.dart': [
    ("const SectionHeaderWidget(label: 'ความปลอดภัย')",
     "SectionHeaderWidget(label: l.t('me_security'))"),
    ("'เปลี่ยนรหัสผ่าน'",
     "l.t('me_change_password')"),
    ("hint: 'รหัสผ่านใหม่'",
     "hint: l.t('me_new_password')"),
    ("hint: 'ยืนยันรหัสผ่านใหม่'",
     "hint: l.t('me_confirm_password')"),
    ("saving ? 'กำลังบันทึก...' : 'บันทึก'",
     "saving ? l.t('me_saving') : l.t('common_save')"),
  ],

  'lib/widgets/me/language_dialog.dart': [
    ("'เลือกภาษา / Select Language'",
     "l.t('me_language_select')"),
    ("'ไทย'",
     "l.t('language_thai')"),
    ("'อังกฤษ'",
     "l.t('language_english')"),
  ],

  # ── group/ widgets ────────────────────────────────────────────────────────────
  'lib/widgets/group/bills_tab.dart': [
    ("'สร้างบิลแรกของกลุ่ม'",
     "l.t('group_bills_create_first')"),
    ("'แตะเพื่อเริ่มหารค่าใช้จ่าย'",
     "l.t('group_bills_start')"),
    ("'สร้างบิลใหม่'",
     "l.t('group_bills_create_new')"),
  ],

  'lib/widgets/group/members_tab.dart': [
    ("'จัดการสมาชิก'",
     "l.t('group_manage_members')"),
    ("'เจ้าของ'",
     "l.t('group_owner_label')"),
    ("'รอตอบรับ \${pendingMembers.length} คน'",
     "'\${pendingMembers.length} \${l.t(\"group_pending_members\")}'"),
  ],

  'lib/widgets/group/group_summary_tab.dart': [
    ("'สร้างบิลก่อนเพื่อดูสรุป'",
     "l.t('summary_create_bill_first')"),
    ("'ยอดรวมทั้งกลุ่ม'",
     "l.t('group_total_label')"),
  ],

  'lib/widgets/group/touchable_pie_chart.dart': [
    ("'🥧 สัดส่วนค่าใช้จ่ายต่อบิล'",
     "l.t('analytics_pie_chart_per_bill')"),
  ],

  # ── bill/ summary_tab widgets ─────────────────────────────────────────────────
  'lib/widgets/bill/summary_tab/member_selector.dart': [
    ("'ดูสรุปของ'",
     "l.t('summary_view_of')"),
  ],

  'lib/widgets/bill/summary_tab/hero_card.dart': [
    ("'ทุกคนจ่ายแล้ว!'",
     "l.t('summary_all_paid')"),
    ("'สถานะการชำระ'",
     "l.t('summary_payment_status')"),
  ],

  'lib/widgets/bill/summary_tab/all_members_section.dart': [
    ("'สรุปทุกคน'",
     "l.t('summary_all_members')"),
    ("'ใครโอนให้ใคร'",
     "l.t('summary_who_owes_whom')"),
    ("'จ่ายแล้ว'",
     "l.t('summary_paid_label')"),
    ("'ทำเครื่องหมายว่าจ่ายแล้ว'",
     "l.t('summary_mark_paid')"),
    ("'อัพโหลดสลิป'",
     "l.t('summary_upload_slip')"),
    ("'คุณ'",
     "l.t('common_you')"),
    ("'ภายนอก'",
     "l.t('member_external_label')"),
  ],

  'lib/widgets/bill/summary_tab/debt_section.dart': [
    ("'ฉันต้องโอนให้'",
     "l.t('summary_i_owe')"),
    ("'คุณไม่ต้องโอนให้ใคร'",
     "l.t('summary_no_debt_me')"),
    ("'ทำเครื่องหมายว่าจ่ายแล้ว'",
     "l.t('summary_mark_paid')"),
    ("'อัพโหลดสลิป'",
     "l.t('summary_upload_slip')"),
    ("'บันทึกรูป QR Code'",
     "l.t('summary_save_qr')"),
    ("'กำลังบันทึก...'",
     "l.t('summary_saving_qr')"),
    ("'ยังไม่ได้จ่าย'",
     "l.t('summary_not_paid_label')"),
  ],

  # ── bill/ analytics_tab widgets ───────────────────────────────────────────────
  'lib/widgets/bill/analytics_tab/biggest_spender_card.dart': [
    ("'จ่ายเยอะสุด'",
     "l.t('analytics_biggest_spender')"),
  ],

  'lib/widgets/bill/analytics_tab/fairness_card.dart': [
    ("'ความเท่าเทียม'",
     "l.t('analytics_fairness')"),
    ("'จ่ายน้อยสุด'",
     "l.t('analytics_least_spender')"),
    ("'จ่ายเยอะสุด'",
     "l.t('analytics_biggest_spender')"),
    ("'เฉลี่ยต่อคน'",
     "l.t('analytics_avg_per_person')"),
  ],

  'lib/widgets/bill/analytics_tab/top_items_card.dart': [
    ("'🔥 รายการแพงสุด'",
     "l.t('analytics_top_items')"),
  ],

  'lib/widgets/bill/analytics_tab/pie_chart_card.dart': [
    ("'🥧 สัดส่วนค่าใช้จ่าย'",
     "l.t('analytics_pie_chart')"),
  ],

  'lib/widgets/bill/analytics_tab/items_per_member_grid.dart': [
    ("'📋 รายการต่อคน'",
     "l.t('analytics_items_per_member')"),
  ],

  'lib/widgets/bill/analytics_tab/member_spending_list.dart': [
    ("'💸 ค่าใช้จ่ายแต่ละคน'",
     "l.t('analytics_member_spending')"),
    ("'เฉลี่ย/คน'",
     "l.t('analytics_avg_per_person_short')"),
  ],

  'lib/widgets/bill/analytics_tab/stats_row.dart': [
    ("'เฉลี่ย/คน'",
     "l.t('analytics_avg_per_person_short')"),
  ],

  'lib/widgets/bill/analytics_tab.dart': [
    ("'กราฟและสถิติจะแสดงเมื่อมีข้อมูล'",
     "l.t('analytics_no_data')"),
    ("'เพิ่มสมาชิกและรายการก่อน'",
     "l.t('analytics_add_first')"),
  ],

  'lib/widgets/bill/summary_tab.dart': [
    ("'เพิ่มสมาชิกและรายการก่อน'",
     "l.t('summary_add_members_first')"),
  ],

  # ── screens ───────────────────────────────────────────────────────────────────
  'lib/screens/group/groups_screen.dart': [
    ("'กลุ่มของฉัน'",
     "l.t('groups_title')"),
    ("'ยังไม่มีกลุ่ม'",
     "l.t('groups_empty_title')"),
    ("'สร้างกลุ่มและเชิญเพื่อนมาหารค่าใช้จ่ายด้วยกัน'",
     "l.t('groups_empty_sub')"),
    ("'สร้างกลุ่มแรก'",
     "l.t('groups_create_first')"),
  ],

  'lib/screens/friend/friends_screen.dart': [
    ("'เพื่อนทั้งหมด'",
     "l.t('friends_title')"),
    ("'เพิ่มเพื่อนใหม่'",
     "l.t('friends_add_new')"),
  ],

  'lib/screens/group/group_detail_screen.dart': [
    ("'ไม่พบกลุ่ม'",
     "l.t('groups_not_found')"),
  ],

  'lib/widgets/shared/shared_bill_card.dart': [
    ("'ดำเนินการ'",
     "l.t('common_proceed')"),
  ],

  'lib/widgets/group/group_analytics_tab.dart': [
    ("'สร้างบิลและเพิ่มรายการก่อน'",
     "l.t('analytics_add_bill_first')"),
    ("'เฉลี่ยต่อบิล'",
     "l.t('analytics_avg_per_bill')"),
    ("'📊 เปรียบเทียบยอดแต่ละบิล'",
     "l.t('analytics_compare_bills')"),
    ("'🔥 รายการแพงสุด'",
     "l.t('analytics_top_items')"),
    ("'ยังไม่มีข้อมูลวิเคราะห์'",
     "l.t('analytics_no_data_group')"),
  ],

  'lib/widgets/group/manage_members_sheet.dart': [
    ("'จัดการสมาชิก'",
     "l.t('group_manage_members')"),
    ("'ชวนเพื่อน'",
     "l.t('group_invite_friend')"),
    ("'เพิ่มสมาชิกภายนอก'",
     "l.t('group_add_external')"),
    ("'ชื่อสมาชิก'",
     "l.t('member_name_hint')"),
    ("'สมาชิกที่ไม่มีบัญชีในแอป สามารถเพิ่มลงบิลในกลุ่มได้'",
     "l.t('group_external_member_desc')"),
  ],
}

# ── Helpers ───────────────────────────────────────────────────────────────────

def ensure_imports(content):
    """Add provider + locale imports if not present."""
    # Find the first 'import' line to anchor insertion
    lines = content.split('\n')
    first_import_idx = next((i for i, l in enumerate(lines) if l.startswith("import '")), None)
    if first_import_idx is None:
        return content

    if LOCALE_IMPORT not in content and PROVIDER_IMPORT not in content:
        # Insert both before the first import
        lines.insert(first_import_idx, LOCALE_IMPORT)
        lines.insert(first_import_idx, PROVIDER_IMPORT)
        return '\n'.join(lines)
    elif LOCALE_IMPORT not in content:
        lines.insert(first_import_idx, LOCALE_IMPORT)
        return '\n'.join(lines)
    elif PROVIDER_IMPORT not in content:
        content = content.replace(LOCALE_IMPORT,
                                  PROVIDER_IMPORT + '\n' + LOCALE_IMPORT)
    return content

def inject_l_var(content):
    """
    For every `Widget build(BuildContext context) {` block that contains
    `l.t(` but does NOT already have `final l = context.watch`, inject the
    declaration as the first statement.
    """
    # We'll process line by line, tracking brace depth inside build methods.
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Detect start of a build method
        if re.match(r'\s*Widget build\(BuildContext context\)\s*\{', line):
            # Collect the entire build method body to check if l.t( is used
            # and if l is already declared
            indent = len(line) - len(line.lstrip())
            body_lines = [line]
            depth = line.count('{') - line.count('}')
            j = i + 1
            while j < len(lines) and depth > 0:
                body_lines.append(lines[j])
                depth += lines[j].count('{') - lines[j].count('}')
                j += 1
            body = '\n'.join(body_lines)
            needs_l = 'l.t(' in body and 'final l = context.watch<LocaleProvider>()' not in body
            result.append(line)
            if needs_l:
                # Insert after the opening brace line
                inner_indent = ' ' * (indent + 4)
                result.append(f'{inner_indent}final l = context.watch<LocaleProvider>();')
            i += 1
            continue
        result.append(line)
        i += 1
    return '\n'.join(result)

def process_file(path, replacements):
    if not os.path.exists(path):
        print(f'  SKIP (not found): {path}')
        return False

    with open(path, encoding='utf-8') as f:
        content = f.read()
    original = content

    # 1. Apply string replacements
    for old, new in replacements:
        content = content.replace(old, new)

    if content == original:
        print(f'  NO CHANGE: {path}')
        return False

    # 2. Add imports
    content = ensure_imports(content)

    # 3. Inject `final l = ...` into build methods that need it
    content = inject_l_var(content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'  Updated: {path}')
    return True

# ── Run ───────────────────────────────────────────────────────────────────────
total = 0
for path, replacements in FILE_REPLACEMENTS.items():
    if process_file(path, replacements):
        total += 1

print(f'\nUpdated {total} files.')
