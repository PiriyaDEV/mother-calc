#!/usr/bin/env python3
"""
Final i18n wiring pass — covers all remaining hardcoded Thai strings.
Adds new keys to th.json/en.json and replaces strings in Dart files.
"""
import json, os, re

TH_PATH = 'assets/i18n/th.json'
EN_PATH = 'assets/i18n/en.json'

# ── New keys to add ───────────────────────────────────────────────────────────
NEW_KEYS = {
    # home
    'home_greeting': ('สวัสดี, {name} 👋 !', 'Hello, {name} 👋 !'),
    'home_main_menu': ('เมนูหลัก', 'Main Menu'),
    'home_nav_bills': ('บิล', 'Bills'),
    'home_nav_bills_sub': ('จัดการบิล', 'Manage Bills'),
    'home_nav_groups': ('กลุ่ม', 'Groups'),
    'home_nav_groups_sub': ('จัดการกลุ่ม', 'Manage Groups'),
    'home_nav_friends': ('เพื่อน', 'Friends'),
    'home_nav_friends_sub': ('จัดการ', 'Manage'),
    'home_exchange_rate': ('อัตราแลกเปลี่ยน', 'Exchange Rate'),
    'home_stats_title': ('สถิติของคุณ', 'Your Stats'),
    'home_recent_bills': ('บิลล่าสุด', 'Recent Bills'),
    'home_see_all': ('ดูทั้งหมด', 'See All'),
    'home_you': ('คุณ', 'You'),
    # stats grid
    'stats_avg_per_bill': ('เฉลี่ย/บิล', 'Avg/Bill'),
    'stats_total_bills': ('บิลทั้งหมด', 'Total Bills'),
    'stats_total_items': ('รายการทั้งหมด', 'Total Items'),
    'stats_biggest_bill': ('บิลใหญ่สุด', 'Biggest Bill'),
    # nav shell
    'nav_home': ('หน้าหลัก', 'Home'),
    'nav_bills': ('บิล', 'Bills'),
    'nav_groups': ('กลุ่ม', 'Groups'),
    'nav_friends': ('เพื่อน', 'Friends'),
    'nav_me': ('ฉัน', 'Me'),
    # login / install
    'login_install_prompt': ('บันทึก Kidtang ไปที่หน้าจอหลัก', 'Add Kidtang to Home Screen'),
    'login_install_sub': ('เพื่อเปิดแอปได้เร็วขึ้นในครั้งถัดไป เหมือนแอปทั่วไป', 'Open the app faster next time, just like a native app'),
    # onboarding
    'onboarding_welcome': ('ยินดีต้อนรับ 👋', 'Welcome 👋'),
    'onboarding_setup_profile': ('ตั้งค่าโปรไฟล์ก่อนเริ่มใช้งาน', 'Set up your profile to get started'),
    'onboarding_display_name_label': ('ชื่อที่แสดง', 'Display Name'),
    'onboarding_display_name_hint': ('เช่น สมชาย ใจดี', 'e.g. John Doe'),
    'onboarding_display_name_required': ('กรุณาใส่ชื่อที่แสดง', 'Please enter a display name'),
    'onboarding_username_label': ('ชื่อผู้ใช้ (@username)', 'Username (@username)'),
    'onboarding_username_hint': ('เช่น somchai99', 'e.g. johndoe99'),
    'onboarding_username_required': ('กรุณาใส่ชื่อผู้ใช้', 'Please enter a username'),
    'onboarding_username_invalid': ('ใช้ได้แค่ a-z, 0-9, _ และ 3-30 ตัวอักษร', 'Only a-z, 0-9, _ and 3-30 characters'),
    'onboarding_username_taken': ('ชื่อผู้ใช้นี้ถูกใช้แล้ว', 'This username is already taken'),
    'onboarding_promptpay_label': ('เบอร์พร้อมเพย์', 'PromptPay Number'),
    'onboarding_promptpay_hint': ('เช่น 0812345678', 'e.g. 0812345678'),
    'onboarding_promptpay_required': ('กรุณาใส่เบอร์พร้อมเพย์', 'Please enter your PromptPay number'),
    'onboarding_promptpay_invalid': ('เบอร์พร้อมเพย์ต้องมี 10 หลัก', 'PromptPay number must be 10 digits'),
    'onboarding_start': ('เริ่มใช้งาน', 'Get Started'),
    # notifications screen
    'notifications_title': ('การแจ้งเตือน', 'Notifications'),
    'notifications_mark_all_read': ('อ่านทั้งหมด', 'Mark All Read'),
    'notifications_empty_title': ('ไม่มีการแจ้งเตือน', 'No Notifications'),
    'notifications_empty_sub': ('คำเชิญกลุ่มและการอัพเดตจะปรากฏที่นี่', 'Group invites and updates will appear here'),
    'notifications_user_fallback': ('ผู้ใช้', 'User'),
    'notifications_responding': ('กำลังดำเนินการ...', 'Processing...'),
    'notifications_decline': ('ปฏิเสธ', 'Decline'),
    'notifications_accept': ('รับคำเชิญ', 'Accept'),
    'notifications_view_friend_request': ('ดูคำขอเป็นเพื่อน', 'View Friend Request'),
    # friends screen
    'friends_tab_label': ('เพื่อน', 'Friends'),
    'friends_add_btn': ('เพิ่มเพื่อน', 'Add Friend'),
    'friends_remove_title': ('ลบเพื่อน?', 'Remove Friend?'),
    'friends_remove_desc': ('ต้องการลบ {name} ออกจากรายชื่อเพื่อนหรือไม่?', 'Remove {name} from your friends list?'),
    'friends_remove_confirm': ('ลบ', 'Remove'),
    'friends_fallback': ('เพื่อน', 'Friend'),
    # bill detail
    'bill_not_found': ('ไม่พบบิล', 'Bill not found'),
    'bill_tab_members': ('สมาชิก', 'Members'),
    # create bill
    'create_bill_title_new': ('สร้างบิลใหม่', 'Create New Bill'),
    'create_bill_title_edit': ('แก้ไขบิล', 'Edit Bill'),
    'create_bill_submit_new': ('สร้างบิล', 'Create Bill'),
    'create_bill_submit_edit': ('บันทึกบิล', 'Save Bill'),
    'create_bill_delete_title': ('ลบบิลนี้?', 'Delete this bill?'),
    'create_bill_delete_desc': ('บิลและข้อมูลทั้งหมดจะถูกลบถาวร ไม่สามารถกู้คืนได้', 'The bill and all its data will be permanently deleted.'),
    'create_bill_delete_confirm': ('ลบ', 'Delete'),
    'create_bill_name_label': ('ชื่อบิล *', 'Bill Name *'),
    'create_bill_name_hint': ('เช่น ข้าวเย็น, ปาร์ตี้...', 'e.g. Dinner, Party...'),
    'create_bill_desc_label': ('คำอธิบาย (ไม่บังคับ)', 'Description (optional)'),
    'create_bill_desc_hint': ('คำอธิบายเพิ่มเติม...', 'Additional description...'),
    'create_bill_tags_label': ('แท็ก', 'Tags'),
    'create_bill_tag_hint': ('เพิ่มแท็กเอง...', 'Add custom tag...'),
    'create_bill_settings_label': ('ตั้งค่าบิล', 'Bill Settings'),
    'create_bill_off': ('ปิดอยู่', 'Off'),
    'create_bill_currency_label': ('สกุลเงิน', 'Currency'),
    'create_bill_rounding_label': ('การปัดเศษ', 'Rounding'),
    # create group
    'create_group_title_new': ('สร้างกลุ่มใหม่', 'Create New Group'),
    'create_group_title_edit': ('แก้ไขกลุ่ม', 'Edit Group'),
    'create_group_submit_new': ('สร้างกลุ่ม', 'Create Group'),
    'create_group_submit_edit': ('บันทึกกลุ่ม', 'Save Group'),
    'create_group_delete_title': ('ลบกลุ่มนี้?', 'Delete this group?'),
    'create_group_delete_desc': ('กลุ่มและข้อมูลทั้งหมดจะถูกลบถาวร ไม่สามารถกู้คืนได้', 'The group and all its data will be permanently deleted.'),
    'create_group_delete_confirm': ('ลบ', 'Delete'),
    'create_group_name_label': ('ชื่อกลุ่ม *', 'Group Name *'),
    'create_group_name_hint': ('ชื่อกลุ่ม', 'Group name'),
    'create_group_desc_label': ('คำอธิบาย (ไม่บังคับ)', 'Description (optional)'),
    'create_group_desc_hint': ('คำอธิบายเพิ่มเติม...', 'Additional description...'),
    'create_group_tags_label': ('แท็ก', 'Tags'),
    'create_group_tag_hint': ('เพิ่มแท็กเอง...', 'Add custom tag...'),
    # me screen
    'me_logout_title': ('ออกจากระบบ', 'Sign Out'),
    'me_logout_confirm_msg': ('ต้องการออกจากระบบหรือไม่?', 'Are you sure you want to sign out?'),
    'me_logout_cancel': ('ยกเลิก', 'Cancel'),
    'me_logout_confirm': ('ออกจากระบบ', 'Sign Out'),
    'me_logout_btn': ('ออกจากระบบ', 'Sign Out'),
    'me_save_name_success': ('บันทึกชื่อเรียบร้อย', 'Name saved'),
    'me_save_username_success': ('บันทึก username เรียบร้อย', 'Username saved'),
    'me_save_promptpay_success': ('บันทึกพร้อมเพย์เรียบร้อย', 'PromptPay saved'),
    'me_password_min_length': ('รหัสผ่านต้องมีอย่างน้อย 6 ตัว', 'Password must be at least 6 characters'),
    'me_password_mismatch': ('รหัสผ่านไม่ตรงกัน', 'Passwords do not match'),
    'me_change_password_success': ('เปลี่ยนรหัสผ่านเรียบร้อย', 'Password changed'),
    'me_upload_avatar_success': ('อัปโหลดรูปโปรไฟล์เรียบร้อย', 'Profile photo uploaded'),
    'me_upload_avatar_fail': ('อัปโหลดรูปไม่สำเร็จ', 'Failed to upload photo'),
    'me_error_generic': ('เกิดข้อผิดพลาด กรุณาลองใหม่', 'An error occurred. Please try again.'),
    # profile screen
    'profile_edit_title': ('แก้ไขโปรไฟล์', 'Edit Profile'),
    'profile_save_btn': ('บันทึก', 'Save'),
    'profile_save_changes': ('บันทึกการเปลี่ยนแปลง', 'Save Changes'),
    'profile_display_name_label': ('ชื่อที่แสดง', 'Display Name'),
    'profile_display_name_hint': ('ชื่อที่แสดงในแอป', 'Name shown in the app'),
    'profile_username_label': ('ชื่อผู้ใช้', 'Username'),
    'profile_promptpay_label': ('เบอร์ PromptPay', 'PromptPay Number'),
    'profile_promptpay_hint': ('เบอร์โทรหรือเลขบัตรประชาชน', 'Phone or national ID'),
    'profile_email_label': ('อีเมล', 'Email'),
    'profile_error': ('เกิดข้อผิดพลาด', 'An error occurred'),
    # bill widgets
    'bill_member_external': ('ภายนอก', 'External'),
    'bill_member_me': ('ฉัน', 'Me'),
    'bill_member_friend': ('เพื่อน', 'Friend'),
    'member_form_add_title': ('เพิ่มสมาชิก', 'Add Member'),
    'member_form_edit_title': ('แก้ไขสมาชิก', 'Edit Member'),
    'member_form_add_from_group': ('เพิ่มจากกลุ่ม', 'Add from Group'),
    'member_form_or_new': ('หรือเพิ่มสมาชิกใหม่', 'Or add new member'),
    'member_form_name_hint': ('ชื่อสมาชิก', 'Member name'),
    'member_form_promptpay_hint': ('เบอร์ PromptPay (ไม่บังคับ)', 'PromptPay (optional)'),
    'member_form_color_label': ('สีประจำตัว', 'Color'),
    'member_form_save': ('บันทึก', 'Save'),
    'member_form_add_btn': ('เพิ่มสมาชิก', 'Add Member'),
    'item_form_add_title': ('เพิ่มรายการ', 'Add Item'),
    'item_form_edit_title': ('แก้ไขรายการ', 'Edit Item'),
    'item_form_name_hint': ('ชื่อรายการ', 'Item name'),
    'item_form_price_hint': ('ราคา', 'Price'),
    'item_form_split_method': ('วิธีหาร', 'Split Method'),
    'item_form_split_equal': ('เท่ากัน', 'Equal'),
    'item_form_split_custom': ('ไม่เท่ากัน', 'Custom'),
    'item_form_members_label': ('สมาชิกที่ร่วมจ่าย', 'Members sharing'),
    'item_form_weight_hint': ('น้ำหนัก', 'Weight'),
    'item_form_weight_total': ('น้ำหนักรวม: {total}', 'Total weight: {total}'),
    'item_form_weight_incomplete': ('กรุณาใส่น้ำหนักให้ครบ', 'Please fill in all weights'),
    'item_form_paid_by': ('ใครจ่ายก่อน? (ไม่บังคับ)', 'Who paid first? (optional)'),
    'item_form_paid_by_none': ('ไม่ระบุ', 'None'),
    'item_form_save': ('บันทึก', 'Save'),
    'item_form_add_btn': ('เพิ่มรายการ', 'Add Item'),
    'item_form_per_person': ('฿{amount}/คน ({count} คน)', '฿{amount}/person ({count} people)'),
    'items_tab_add': ('เพิ่มรายการ', 'Add Item'),
    'members_tab_add': ('เพิ่มสมาชิก', 'Add Member'),
    'item_tile_unequal': ('หารไม่เท่า', 'Unequal split'),
    'item_tile_paid_by': ('จ่ายโดย', 'Paid by'),
    # bill status
    'bill_status_completed': ('เสร็จแล้ว', 'Completed'),
    'bill_status_pending': ('รอจ่าย', 'Pending'),
    'bill_status_draft': ('ดราฟ', 'Draft'),
    # bill summary card
    'summary_subtotal': ('ยอดรวมก่อนภาษี', 'Subtotal'),
    'summary_tip': ('ทิป', 'Tip'),
    'summary_discount': ('ส่วนลด', 'Discount'),
    'summary_grand_total': ('ยอดรวมทั้งหมด', 'Grand Total'),
    # bill breakdown card
    'breakdown_title': ('รายละเอียดบิล', 'Bill Breakdown'),
    'breakdown_subtotal': ('ยอดรวมสินค้า', 'Items Subtotal'),
    'breakdown_tip': ('ทิป', 'Tip'),
    'breakdown_discount': ('ส่วนลด', 'Discount'),
    'breakdown_total': ('รวมทั้งสิ้น', 'Total'),
    # hero card
    'hero_grand_total': ('ยอดรวมทั้งสิ้น', 'Grand Total'),
    'hero_service_charge': ('รวม Service Charge {pct}%', 'Incl. Service Charge {pct}%'),
    'hero_vat': ('รวม VAT {pct}%', 'Incl. VAT {pct}%'),
    # selected member card
    'selected_member_external': ('ภายนอก', 'External'),
    'selected_member_you': ('คุณ', 'You'),
    'selected_member_promptpay': ('พร้อมเพย์: {pp}', 'PromptPay: {pp}'),
    'selected_member_share_title': ('{emoji} ส่วนของ{name}', '{emoji} {name}\'s share'),
    'selected_member_share_me': ('ฉัน', 'me'),
    'selected_member_items_ordered': ('รายการที่สั่ง', 'Items Ordered'),
    'selected_member_total_with_tax': ('รวม (รวม VAT/SC)', 'Total (incl. VAT/SC)'),
    # all members section
    'all_members_promptpay': ('พร้อมเพย์: {pp}', 'PromptPay: {pp}'),
    # debt section
    'debt_promptpay': ('พร้อมเพย์: {pp}', 'PromptPay: {pp}'),
    'debt_scan_qr': ('สแกนโอนให้ {name}', 'Scan to pay {name}'),
    'debt_save_qr_success': ('บันทึก QR Code แล้ว 🎉', 'QR Code saved 🎉'),
    'debt_save_qr_fail': ('บันทึกไม่สำเร็จ', 'Save failed'),
    'debt_save_qr_fail_msg': ('บันทึกไม่สำเร็จ', 'Failed to save QR code'),
    # slip upload
    'slip_upload_title': ('อัพโหลดสลิปการโอน', 'Upload Transfer Slip'),
    'slip_upload_sub': ('เลือกหลักฐานการโอนเงิน เพื่อยืนยันการชำระ', 'Select proof of transfer to confirm payment'),
    'slip_from_gallery': ('เลือกจากคลังรูป', 'Choose from Gallery'),
    'slip_take_photo': ('ถ่ายภาพ', 'Take Photo'),
    'slip_confirm_title': ('ยืนยันการชำระเงิน', 'Confirm Payment'),
    'slip_confirm_msg': ('ยืนยันว่าคุณได้ทำการโอนเงินแล้ว?', 'Confirm that you have transferred the money?'),
    'slip_cancel': ('ยกเลิก', 'Cancel'),
    'slip_confirm_btn': ('ยืนยัน', 'Confirm'),
    # member selector
    'member_selector_you': ('คุณ', 'You'),
    # analytics stats row
    'analytics_items_label': ('รายการ', 'Items'),
    'analytics_members_label': ('สมาชิก', 'Members'),
    # group manage members
    'group_external_added': ('เพิ่ม "{name}" เรียบร้อย', '"{name}" added'),
    # bills screen
    'bills_group_fallback': ('กลุ่ม', 'Group'),
}

def update_json_files():
    with open(TH_PATH, encoding='utf-8') as f:
        th = json.load(f)
    with open(EN_PATH, encoding='utf-8') as f:
        en = json.load(f)
    added = 0
    for key, (th_val, en_val) in NEW_KEYS.items():
        if key not in th:
            th[key] = th_val
            added += 1
        if key not in en:
            en[key] = en_val
    with open(TH_PATH, 'w', encoding='utf-8') as f:
        json.dump(th, f, ensure_ascii=False, indent=2)
    with open(EN_PATH, 'w', encoding='utf-8') as f:
        json.dump(en, f, ensure_ascii=False, indent=2)
    print(f'Added {added} new keys to JSON files.')

PROVIDER_IMPORT = "import 'package:provider/provider.dart';"
LOCALE_IMPORT   = "import 'package:kidtang_flutter/providers/locale_provider.dart';"

FILE_REPLACEMENTS = {
    'lib/widgets/home/stats_grid.dart': [
        ("label: 'บิลทั้งหมด'", "label: l.t('stats_total_bills')"),
        ("label: 'รายการทั้งหมด'", "label: l.t('stats_total_items')"),
        ("label: 'บิลใหญ่สุด'", "label: l.t('stats_biggest_bill')"),
    ],
    'lib/widgets/home/hero_balance_card.dart': [
        ("'ยอดรวมทั้งหมด'", "l.t('home_stats_title')"),
    ],
    'lib/screens/shared/main_shell.dart': [
        ("label: 'หน้าหลัก'", "label: l.t('nav_home')"),
        ("label: 'บิล'", "label: l.t('nav_bills')"),
        ("label: 'กลุ่ม'", "label: l.t('nav_groups')"),
        ("label: 'เพื่อน', badge:", "label: l.t('nav_friends'), badge:"),
        ("label: 'ฉัน', badge:", "label: l.t('nav_me'), badge:"),
    ],
    'lib/screens/shared/login_screen.dart': [
        ("'บันทึก Kidtang ไปที่หน้าจอหลัก'", "l.t('login_install_prompt')"),
        ("'เพื่อเปิดแอปได้เร็วขึ้นในครั้งถัดไป เหมือนแอปทั่วไป'", "l.t('login_install_sub')"),
    ],
    'lib/screens/shared/onboarding_screen.dart': [
        ("'ยินดีต้อนรับ 👋'", "l.t('onboarding_welcome')"),
        ("'ตั้งค่าโปรไฟล์ก่อนเริ่มใช้งาน'", "l.t('onboarding_setup_profile')"),
        ("_label(isDark, 'ชื่อที่แสดง')", "_label(isDark, l.t('onboarding_display_name_label'))"),
        ("_inputDecoration(isDark, 'เช่น สมชาย ใจดี')", "_inputDecoration(isDark, l.t('onboarding_display_name_hint'))"),
        ("? 'กรุณาใส่ชื่อที่แสดง' : null", ": l.t('onboarding_display_name_required') : null"),
        ("_label(isDark, 'ชื่อผู้ใช้ (@username)')", "_label(isDark, l.t('onboarding_username_label'))"),
        ("_inputDecoration(isDark, 'เช่น somchai99')", "_inputDecoration(isDark, l.t('onboarding_username_hint'))"),
        ("return 'กรุณาใส่ชื่อผู้ใช้'", "return l.t('onboarding_username_required')"),
        ("return 'ใช้ได้แค่ a-z, 0-9, _ และ 3-30 ตัวอักษร'", "return l.t('onboarding_username_invalid')"),
        ("_label(isDark, 'เบอร์พร้อมเพย์')", "_label(isDark, l.t('onboarding_promptpay_label'))"),
        ("_inputDecoration(isDark, 'เช่น 0812345678')", "_inputDecoration(isDark, l.t('onboarding_promptpay_hint'))"),
        ("return 'กรุณาใส่เบอร์พร้อมเพย์'", "return l.t('onboarding_promptpay_required')"),
        ("return 'เบอร์พร้อมเพย์ต้องมี 10 หลัก'", "return l.t('onboarding_promptpay_invalid')"),
        ("'เริ่มใช้งาน'", "l.t('onboarding_start')"),
        ("final isUsernameTaken = err == 'ชื่อผู้ใช้นี้ถูกใช้แล้ว'",
         "final isUsernameTaken = err == l.t('onboarding_username_taken')"),
    ],
    'lib/screens/home/home_screen.dart': [
        ("'สวัสดี, $firstName 👋 !'", "l.t('home_greeting').replaceAll('{name}', firstName)"),
        ("'เมนูหลัก'", "l.t('home_main_menu')"),
        ("label: 'บิล',\n                                      sublabel: 'จัดการบิล'",
         "label: l.t('home_nav_bills'),\n                                      sublabel: l.t('home_nav_bills_sub')"),
        ("label: 'กลุ่ม',\n                                      sublabel: 'จัดการกลุ่ม'",
         "label: l.t('home_nav_groups'),\n                                      sublabel: l.t('home_nav_groups_sub')"),
        ("label: 'เพื่อน',\n                                      sublabel: 'จัดการ'",
         "label: l.t('home_nav_friends'),\n                                      sublabel: l.t('home_nav_friends_sub')"),
        ("'อัตราแลกเปลี่ยน${_ratesUpdated.isNotEmpty ? ' · $_ratesUpdated' : ''}'",
         "l.t('home_exchange_rate') + (_ratesUpdated.isNotEmpty ? ' · \$_ratesUpdated' : '')"),
        ("'สถิติของคุณ'", "l.t('home_stats_title')"),
        ("'บิลล่าสุด'", "l.t('home_recent_bills')"),
        ("'ดูทั้งหมด'", "l.t('home_see_all')"),
    ],
    'lib/screens/friend/notifications_screen.dart': [
        ("'การแจ้งเตือน'", "l.t('notifications_title')"),
        ("'อ่านทั้งหมด'", "l.t('notifications_mark_all_read')"),
        ("title: 'ไม่มีการแจ้งเตือน'", "title: l.t('notifications_empty_title')"),
        ("subtitle: 'คำเชิญกลุ่มและการอัพเดตจะปรากฏที่นี่'", "subtitle: l.t('notifications_empty_sub')"),
        ("isResponding ? 'กำลังดำเนินการ...' : 'ปฏิเสธ'",
         "isResponding ? l.t('notifications_responding') : l.t('notifications_decline')"),
        ("isResponding ? 'กำลังดำเนินการ...' : 'รับคำเชิญ'",
         "isResponding ? l.t('notifications_responding') : l.t('notifications_accept')"),
        ("'ดูคำขอเป็นเพื่อน'", "l.t('notifications_view_friend_request')"),
    ],
    'lib/screens/friend/friends_screen.dart': [
        ("'เพื่อน'", "l.t('friends_tab_label')"),
        ("'เพิ่มเพื่อน'", "l.t('friends_add_btn')"),
        ("title: 'ลบเพื่อน?'", "title: l.t('friends_remove_title')"),
        ("'ต้องการลบ $name ออกจากรายชื่อเพื่อนหรือไม่?'",
         "l.t('friends_remove_desc').replaceAll('{name}', name)"),
        ("confirmLabel: 'ลบ'", "confirmLabel: l.t('friends_remove_confirm')"),
    ],
    'lib/screens/bill/bill_detail_screen.dart': [
        ("'ไม่พบบิล'", "l.t('bill_not_found')"),
        ("CountTab(label: 'สมาชิก', count:", "CountTab(label: l.t('bill_tab_members'), count:"),
    ],
    'lib/screens/bill/create_bill_screen.dart': [
        ("title: 'ลบบิลนี้?'", "title: l.t('create_bill_delete_title')"),
        ("description: 'บิลและข้อมูลทั้งหมดจะถูกลบถาวร ไม่สามารถกู้คืนได้'",
         "description: l.t('create_bill_delete_desc')"),
        ("confirmLabel: 'ลบ'", "confirmLabel: l.t('create_bill_delete_confirm')"),
        ("final titleText = _isEdit ? 'แก้ไขบิล' : 'สร้างบิลใหม่'",
         "final titleText = _isEdit ? l.t('create_bill_title_edit') : l.t('create_bill_title_new')"),
        ("final submitLabel = _isEdit ? 'บันทึกบิล' : 'สร้างบิล'",
         "final submitLabel = _isEdit ? l.t('create_bill_submit_edit') : l.t('create_bill_submit_new')"),
        ("const FormSectionLabel(label: 'ชื่อบิล *')",
         "FormSectionLabel(label: l.t('create_bill_name_label'))"),
        ("hintText: 'เช่น ข้าวเย็น, ปาร์ตี้...'", "hintText: l.t('create_bill_name_hint')"),
        ("const FormSectionLabel(label: 'คำอธิบาย (ไม่บังคับ)')",
         "FormSectionLabel(label: l.t('create_bill_desc_label'))"),
        ("hintText: 'คำอธิบายเพิ่มเติม...'", "hintText: l.t('create_bill_desc_hint')"),
        ("const FormSectionLabel(label: 'แท็ก')",
         "FormSectionLabel(label: l.t('create_bill_tags_label'))"),
        ("hintText: 'เพิ่มแท็กเอง...'", "hintText: l.t('create_bill_tag_hint')"),
        ("'ตั้งค่าบิล'", "l.t('create_bill_settings_label')"),
        ("'ปิดอยู่'", "l.t('create_bill_off')"),
        ("const FormSectionLabel(label: 'สกุลเงิน')",
         "FormSectionLabel(label: l.t('create_bill_currency_label'))"),
        ("const FormSectionLabel(label: 'การปัดเศษ')",
         "FormSectionLabel(label: l.t('create_bill_rounding_label'))"),
    ],
    'lib/screens/group/create_group_screen.dart': [
        ("title: 'ลบกลุ่มนี้?'", "title: l.t('create_group_delete_title')"),
        ("description: 'กลุ่มและข้อมูลทั้งหมดจะถูกลบถาวร ไม่สามารถกู้คืนได้'",
         "description: l.t('create_group_delete_desc')"),
        ("confirmLabel: 'ลบ'", "confirmLabel: l.t('create_group_delete_confirm')"),
        ("final titleText = _isEdit ? 'แก้ไขกลุ่ม' : 'สร้างกลุ่มใหม่'",
         "final titleText = _isEdit ? l.t('create_group_title_edit') : l.t('create_group_title_new')"),
        ("final submitLabel = _isEdit ? 'บันทึกกลุ่ม' : 'สร้างกลุ่ม'",
         "final submitLabel = _isEdit ? l.t('create_group_submit_edit') : l.t('create_group_submit_new')"),
        ("const FormSectionLabel(label: 'ชื่อกลุ่ม *')",
         "FormSectionLabel(label: l.t('create_group_name_label'))"),
        ("decoration: const InputDecoration(hintText: 'ชื่อกลุ่ม')",
         "decoration: InputDecoration(hintText: l.t('create_group_name_hint'))"),
        ("const FormSectionLabel(label: 'คำอธิบาย (ไม่บังคับ)')",
         "FormSectionLabel(label: l.t('create_group_desc_label'))"),
        ("decoration: const InputDecoration(hintText: 'คำอธิบายเพิ่มเติม...')",
         "decoration: InputDecoration(hintText: l.t('create_group_desc_hint'))"),
        ("const FormSectionLabel(label: 'แท็ก')",
         "FormSectionLabel(label: l.t('create_group_tags_label'))"),
        ("hintText: 'เพิ่มแท็กเอง...'", "hintText: l.t('create_group_tag_hint')"),
    ],
    'lib/screens/me/me_screen.dart': [
        ("_showSuccess('บันทึกชื่อเรียบร้อย')", "_showSuccess(l.t('me_save_name_success'))"),
        ("_showError('เกิดข้อผิดพลาด กรุณาลองใหม่')", "_showError(l.t('me_error_generic'))"),
        ("_showSuccess('บันทึก username เรียบร้อย')", "_showSuccess(l.t('me_save_username_success'))"),
        ("_showSuccess('บันทึกพร้อมเพย์เรียบร้อย')", "_showSuccess(l.t('me_save_promptpay_success'))"),
        ("_showError('รหัสผ่านต้องมีอย่างน้อย 6 ตัว')", "_showError(l.t('me_password_min_length'))"),
        ("_showError('รหัสผ่านไม่ตรงกัน')", "_showError(l.t('me_password_mismatch'))"),
        ("_showSuccess('เปลี่ยนรหัสผ่านเรียบร้อย')", "_showSuccess(l.t('me_change_password_success'))"),
        ("_showSuccess('อัปโหลดรูปโปรไฟล์เรียบร้อย')", "_showSuccess(l.t('me_upload_avatar_success'))"),
        ("_showError('อัปโหลดรูปไม่สำเร็จ')", "_showError(l.t('me_upload_avatar_fail'))"),
        ("title: Text('ออกจากระบบ',", "title: Text(l.t('me_logout_title'),"),
        ("content: Text('ต้องการออกจากระบบหรือไม่?',", "content: Text(l.t('me_logout_confirm_msg'),"),
        ("child: Text('ยกเลิก',", "child: Text(l.t('me_logout_cancel'),"),
        ("child: Text('ออกจากระบบ',", "child: Text(l.t('me_logout_confirm'),"),
        ("'ออกจากระบบ'", "l.t('me_logout_btn')"),
    ],
    'lib/screens/me/profile_screen.dart': [
        ("content: Text('เกิดข้อผิดพลาด', style:", "content: Text(l.t('profile_error'), style:"),
        ("title: Text('แก้ไขโปรไฟล์', style:", "title: Text(l.t('profile_edit_title'), style:"),
        ("'บันทึก'", "l.t('profile_save_btn')"),
        ("const _FormLabel(label: 'ชื่อที่แสดง')", "_FormLabel(label: l.t('profile_display_name_label'))"),
        ("const InputDecoration(hintText: 'ชื่อที่แสดงในแอป')",
         "InputDecoration(hintText: l.t('profile_display_name_hint'))"),
        ("const _FormLabel(label: 'ชื่อผู้ใช้')", "_FormLabel(label: l.t('profile_username_label'))"),
        ("const _FormLabel(label: 'เบอร์ PromptPay')", "_FormLabel(label: l.t('profile_promptpay_label'))"),
        ("const InputDecoration(hintText: 'เบอร์โทรหรือเลขบัตรประชาชน')",
         "InputDecoration(hintText: l.t('profile_promptpay_hint'))"),
        ("const _FormLabel(label: 'อีเมล')", "_FormLabel(label: l.t('profile_email_label'))"),
        ("'บันทึกการเปลี่ยนแปลง'", "l.t('profile_save_changes')"),
    ],
    'lib/widgets/bill/member_tile.dart': [
        ("label = 'ภายนอก'", "label = l.t('bill_member_external')"),
        ("label = 'ฉัน'", "label = l.t('bill_member_me')"),
        ("label = 'เพื่อน'", "label = l.t('bill_member_friend')"),
    ],
    'lib/widgets/bill/member_form_sheet.dart': [
        ("isEdit ? 'แก้ไขสมาชิก' : 'เพิ่มสมาชิก'",
         "isEdit ? l.t('member_form_edit_title') : l.t('member_form_add_title')"),
        ("'เพิ่มจากกลุ่ม'", "l.t('member_form_add_from_group')"),
        ("'หรือเพิ่มสมาชิกใหม่'", "l.t('member_form_or_new')"),
        ("const InputDecoration(hintText: 'ชื่อสมาชิก')",
         "InputDecoration(hintText: l.t('member_form_name_hint'))"),
        ("const InputDecoration(hintText: 'เบอร์ PromptPay (ไม่บังคับ)')",
         "InputDecoration(hintText: l.t('member_form_promptpay_hint'))"),
        ("'สีประจำตัว'", "l.t('member_form_color_label')"),
        ("isEdit ? 'บันทึก' : 'เพิ่มสมาชิก'",
         "isEdit ? l.t('member_form_save') : l.t('member_form_add_btn')"),
    ],
    'lib/widgets/bill/item_form_sheet.dart': [
        ("isEdit ? 'แก้ไขรายการ' : 'เพิ่มรายการ'",
         "isEdit ? l.t('item_form_edit_title') : l.t('item_form_add_title')"),
        ("const InputDecoration(hintText: 'ชื่อรายการ')",
         "InputDecoration(hintText: l.t('item_form_name_hint'))"),
        ("const InputDecoration(hintText: 'ราคา')",
         "InputDecoration(hintText: l.t('item_form_price_hint'))"),
        ("'วิธีหาร'", "l.t('item_form_split_method')"),
        ("label: 'เท่ากัน'", "label: l.t('item_form_split_equal')"),
        ("label: 'ไม่เท่ากัน'", "label: l.t('item_form_split_custom')"),
        ("'สมาชิกที่ร่วมจ่าย'", "l.t('item_form_members_label')"),
        ("hintText: 'น้ำหนัก'", "hintText: l.t('item_form_weight_hint')"),
        ("? 'น้ำหนักรวม: $totalWeight'", ": l.t('item_form_weight_total').replaceAll('{total}', totalWeight.toString())"),
        (": 'กรุณาใส่น้ำหนักให้ครบ'", ": l.t('item_form_weight_incomplete')"),
        ("'ใครจ่ายก่อน? (ไม่บังคับ)'", "l.t('item_form_paid_by')"),
        ("'ไม่ระบุ'", "l.t('item_form_paid_by_none')"),
        ("isEdit ? 'บันทึก' : 'เพิ่มรายการ'",
         "isEdit ? l.t('item_form_save') : l.t('item_form_add_btn')"),
    ],
    'lib/widgets/bill/items_tab.dart': [
        ("'เพิ่มรายการ'", "l.t('items_tab_add')"),
    ],
    'lib/widgets/bill/members_tab.dart': [
        ("'เพิ่มสมาชิก'", "l.t('members_tab_add')"),
    ],
    'lib/widgets/bill/item_tile.dart': [
        ("'หารไม่เท่า'", "l.t('item_tile_unequal')"),
        ("'จ่ายโดย'", "l.t('item_tile_paid_by')"),
    ],
    'lib/widgets/bill/bill_status_pill.dart': [
        ("label = 'เสร็จแล้ว'", "label = l.t('bill_status_completed')"),
        ("label = 'รอจ่าย'", "label = l.t('bill_status_pending')"),
        ("label = 'ดราฟ'", "label = l.t('bill_status_draft')"),
    ],
    'lib/widgets/bill/bill_card.dart': [
        ("label = 'เสร็จแล้ว'", "label = l.t('bill_status_completed')"),
        ("label = 'รอจ่าย'", "label = l.t('bill_status_pending')"),
        ("label = 'ดราฟ'", "label = l.t('bill_status_draft')"),
    ],
    'lib/widgets/bill/bill_summary_card.dart': [
        ("label: 'ยอดรวมก่อนภาษี'", "label: l.t('summary_subtotal')"),
        ("label: 'ทิป', value: calc.tipAmount", "label: l.t('summary_tip'), value: calc.tipAmount"),
        ("label: 'ส่วนลด'", "label: l.t('summary_discount')"),
        ("'ยอดรวมทั้งหมด'", "l.t('summary_grand_total')"),
    ],
    'lib/widgets/bill/summary_tab/bill_breakdown_card.dart': [
        ("'รายละเอียดบิล'", "l.t('breakdown_title')"),
        ("label: 'ยอดรวมสินค้า'", "label: l.t('breakdown_subtotal')"),
        ("label: 'ทิป'", "label: l.t('breakdown_tip')"),
        ("label: 'ส่วนลด'", "label: l.t('breakdown_discount')"),
        ("'รวมทั้งสิ้น'", "l.t('breakdown_total')"),
    ],
    'lib/widgets/bill/summary_tab/hero_card.dart': [
        ("'ยอดรวมทั้งสิ้น'", "l.t('hero_grand_total')"),
        ("'รวม Service Charge ${settings.serviceCharge.toStringAsFixed(0)}%'",
         "l.t('hero_service_charge').replaceAll('{pct}', settings.serviceCharge.toStringAsFixed(0))"),
        ("'รวม VAT ${settings.vat.toStringAsFixed(0)}%'",
         "l.t('hero_vat').replaceAll('{pct}', settings.vat.toStringAsFixed(0))"),
    ],
    'lib/widgets/bill/summary_tab/selected_member_card.dart': [
        ("'ภายนอก'", "l.t('selected_member_external')"),
        ("'คุณ'", "l.t('selected_member_you')"),
        ("'พร้อมเพย์: ${member.promptpay}'",
         "l.t('selected_member_promptpay').replaceAll('{pp}', member.promptpay ?? '')"),
        ("'$emoji ส่วนของ${isMe ? 'ฉัน' : member.name}'",
         "l.t('selected_member_share_title').replaceAll('{emoji}', emoji).replaceAll('{name}', isMe ? l.t('selected_member_share_me') : member.name)"),
        ("'รายการที่สั่ง'", "l.t('selected_member_items_ordered')"),
        ("'รวม (รวม VAT/SC)'", "l.t('selected_member_total_with_tax')"),
    ],
    'lib/widgets/bill/summary_tab/all_members_section.dart': [
        ("'พร้อมเพย์: ${member.promptpay}'",
         "l.t('all_members_promptpay').replaceAll('{pp}', member.promptpay ?? '')"),
    ],
    'lib/widgets/bill/summary_tab/debt_section.dart': [
        ("'พร้อมเพย์: ${debt.to.promptpay}'",
         "l.t('debt_promptpay').replaceAll('{pp}', debt.to.promptpay ?? '')"),
        ("'สแกนโอนให้ ${debt.to.name}'",
         "l.t('debt_scan_qr').replaceAll('{name}', debt.to.name)"),
        ("success ? 'บันทึก QR Code แล้ว 🎉' : 'บันทึกไม่สำเร็จ'",
         "success ? l.t('debt_save_qr_success') : l.t('debt_save_qr_fail')"),
        ("content: const Text('บันทึกไม่สำเร็จ')",
         "content: Text(l.t('debt_save_qr_fail_msg'))"),
    ],
    'lib/widgets/bill/summary_tab/slip_upload_helper.dart': [
        ("'อัพโหลดสลิปการโอน'", "l.t('slip_upload_title')"),
        ("'เลือกหลักฐานการโอนเงิน เพื่อยืนยันการชำระ'", "l.t('slip_upload_sub')"),
        ("title: Text('เลือกจากคลังรูป',", "title: Text(l.t('slip_from_gallery'),"),
        ("title: Text('ถ่ายภาพ',", "title: Text(l.t('slip_take_photo'),"),
        ("'ยืนยันการชำระเงิน'", "l.t('slip_confirm_title')"),
        ("'ยืนยันว่าคุณได้ทำการโอนเงินแล้ว?'", "l.t('slip_confirm_msg')"),
        ("child: Text('ยกเลิก', style: GoogleFonts.notoSansThai())",
         "child: Text(l.t('slip_cancel'), style: GoogleFonts.notoSansThai())"),
        ("child: Text('ยืนยัน',", "child: Text(l.t('slip_confirm_btn'),"),
    ],
    'lib/widgets/bill/summary_tab/member_selector.dart': [
        ("'คุณ'", "l.t('member_selector_you')"),
    ],
    'lib/widgets/bill/analytics_tab/stats_row.dart': [
        ("label: 'รายการ'", "label: l.t('analytics_items_label')"),
        ("label: 'สมาชิก'", "label: l.t('analytics_members_label')"),
    ],
    'lib/widgets/group/manage_members_sheet.dart': [
        ("_externalSuccess = 'เพิ่ม \"$name\" เรียบร้อย'",
         "_externalSuccess = l.t('group_external_added').replaceAll('{name}', name)"),
    ],
    'lib/screens/bill/bills_screen.dart': [
        ("final groupName = groupBillList.first.groupName ?? 'กลุ่ม'",
         "final groupName = groupBillList.first.groupName ?? l.t('bills_group_fallback')"),
    ],
}

def ensure_imports(content):
    lines = content.split('\n')
    first_import_idx = next((i for i, ln in enumerate(lines) if ln.startswith("import '")), None)
    if first_import_idx is None:
        return content
    if LOCALE_IMPORT not in content and PROVIDER_IMPORT not in content:
        lines.insert(first_import_idx, LOCALE_IMPORT)
        lines.insert(first_import_idx, PROVIDER_IMPORT)
        return '\n'.join(lines)
    elif LOCALE_IMPORT not in content:
        lines.insert(first_import_idx, LOCALE_IMPORT)
        return '\n'.join(lines)
    elif PROVIDER_IMPORT not in content:
        content = content.replace(LOCALE_IMPORT, PROVIDER_IMPORT + '\n' + LOCALE_IMPORT)
    return content

def inject_l_var(content):
    """Inject `final l = context.watch<LocaleProvider>();` into build() methods that use l.t()."""
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if re.match(r'\s*Widget build\(BuildContext context\)\s*\{', line):
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
                inner_indent = ' ' * (indent + 4)
                result.append(f'{inner_indent}final l = context.watch<LocaleProvider>();')
            i += 1
            continue
        result.append(line)
        i += 1
    return '\n'.join(result)

def inject_l_into_all_context_methods(content):
    """Inject `final l = context.read<LocaleProvider>();` into non-build methods that use l.t()."""
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Match method with BuildContext context param, opening brace on same line
        if re.search(r'BuildContext context', line) and line.rstrip().endswith('{') and \
           not re.match(r'\s*Widget build\(', line):
            indent = len(line) - len(line.lstrip())
            body_lines = [line]
            depth = line.count('{') - line.count('}')
            j = i + 1
            while j < len(lines) and depth > 0:
                body_lines.append(lines[j])
                depth += lines[j].count('{') - lines[j].count('}')
                j += 1
            body = '\n'.join(body_lines)
            needs_l = 'l.t(' in body and 'final l = context' not in body
            result.append(line)
            if needs_l:
                inner_indent = ' ' * (indent + 4)
                result.append(f'{inner_indent}final l = context.read<LocaleProvider>();')
            i += 1
            continue
        result.append(line)
        i += 1
    return '\n'.join(result)

def inject_l_into_state_methods(content):
    """
    For StatefulWidget State classes: inject `final l = context.read<LocaleProvider>();`
    into methods that use l.t() but don't have BuildContext param (they use `context` from State).
    These are methods like `_showSuccess`, `_handleX`, etc.
    """
    # Find methods that: start with `void _` or `Future<void> _`, have no BuildContext param,
    # use l.t(), and don't already have `final l = context`
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Match private methods without BuildContext param
        if re.match(r'\s+(void|Future<void>|String\??) _\w+\([^)]*\)\s*\{', line) and \
           'BuildContext' not in line:
            indent = len(line) - len(line.lstrip())
            body_lines = [line]
            depth = line.count('{') - line.count('}')
            j = i + 1
            while j < len(lines) and depth > 0:
                body_lines.append(lines[j])
                depth += lines[j].count('{') - lines[j].count('}')
                j += 1
            body = '\n'.join(body_lines)
            needs_l = 'l.t(' in body and 'final l = context' not in body
            result.append(line)
            if needs_l:
                inner_indent = ' ' * (indent + 4)
                result.append(f'{inner_indent}final l = context.read<LocaleProvider>();')
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
    for old, new in replacements:
        content = content.replace(old, new)
    if content == original:
        print(f'  NO CHANGE: {path}')
        return False
    content = ensure_imports(content)
    content = inject_l_var(content)
    content = inject_l_into_all_context_methods(content)
    content = inject_l_into_state_methods(content)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'  Updated: {path}')
    return True

# ── Run ───────────────────────────────────────────────────────────────────────
update_json_files()
total = 0
for path, replacements in FILE_REPLACEMENTS.items():
    if process_file(path, replacements):
        total += 1
print(f'\nUpdated {total} Dart files.')
