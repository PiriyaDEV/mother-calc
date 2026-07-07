#!/usr/bin/env python3
"""
Fix wave 5 errors:
1. Broken ternary in item_form_sheet / member_form_sheet
2. member_tile.dart: _buildMemberPill() needs context param
3. all_members_section / debt_section: misplaced l injection
"""
import re, os

def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()

def write(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def fix_ternary(content):
    """
    Fix broken ternary patterns introduced by i18n script:
    Pattern A: `expr ? l.t('x') ? l.t('y')` -> `expr ? l.t('x') : l.t('y')`
    Pattern B: `expr : l.t('x') ? l.t('y')` -> `expr ? l.t('x') : l.t('y')`
    """
    # Pattern A: two consecutive `?` with l.t() calls
    # `? l.t('...') ? l.t(` -> `? l.t('...') : l.t(`
    content = re.sub(
        r"(\? l\.t\([^)]+\)(?:\.[^\s,\n]+)*)\s*\?\s*(l\.t\()",
        r"\1 : \2",
        content
    )
    # Pattern B: line starts with `: l.t(` followed by `? l.t(`
    # `: l.t('x') ? l.t('y')` -> `? l.t('x') : l.t('y')`
    lines = content.split('\n')
    result = []
    for line in lines:
        stripped = line.lstrip()
        if re.match(r":\s*l\.t\(", stripped):
            # `: l.t('x') ? l.t('y')` -> `? l.t('x') : l.t('y')`
            indent = line[:len(line) - len(line.lstrip())]
            fixed = re.sub(
                r"^:\s*(l\.t\([^)]+\)(?:\.[^\s,\n]+)*)\s*\?\s*(l\.t\()",
                r"? \1 : \2",
                stripped
            )
            result.append(indent + fixed)
        else:
            result.append(line)
    return '\n'.join(result)

def fix_member_tile():
    path = 'lib/widgets/bill/member_tile.dart'
    if not os.path.exists(path):
        print(f'  SKIP: {path}')
        return
    c = read(path)
    # Add context param to _buildMemberPill
    c = c.replace(
        'List<Widget> _buildMemberPill() {',
        'List<Widget> _buildMemberPill(BuildContext context) {'
    )
    # Inject l at start of method body
    c = c.replace(
        'List<Widget> _buildMemberPill(BuildContext context) {\n    final String label;',
        'List<Widget> _buildMemberPill(BuildContext context) {\n    final l = context.read<LocaleProvider>();\n    final String label;'
    )
    # Fix call sites
    c = c.replace('_buildMemberPill()', '_buildMemberPill(context)')
    write(path, c)
    print(f'  Fixed: {path}')

def fix_summary_tab_files():
    """Remove misplaced `final l = ...` from inside widget constructor calls"""
    files = [
        'lib/widgets/bill/summary_tab/all_members_section.dart',
        'lib/widgets/bill/summary_tab/debt_section.dart',
    ]
    for path in files:
        if not os.path.exists(path):
            continue
        c = read(path)
        original = c
        # Remove `final l = context.read<LocaleProvider>();` lines that are
        # inside widget constructor argument lists (not at statement level)
        # These appear as lines with extra indentation inside a `(` block
        c = re.sub(
            r'\n(\s+)final l = context\.read<LocaleProvider>\(\);\n(\s+)(billsStore:|bill:|memberId:)',
            r'\n\2\3',
            c
        )
        if c != original:
            write(path, c)
            print(f'  Fixed: {path}')
        else:
            print(f'  No changes: {path}')

def fix_ternary_files():
    files = [
        'lib/widgets/bill/item_form_sheet.dart',
        'lib/widgets/bill/member_form_sheet.dart',
        'lib/screens/bill/create_bill_screen.dart',
        'lib/screens/friend/friends_screen.dart',
        'lib/screens/friend/notifications_screen.dart',
        'lib/screens/group/create_group_screen.dart',
        'lib/screens/me/me_screen.dart',
        'lib/screens/me/profile_screen.dart',
        'lib/screens/shared/onboarding_screen.dart',
        'lib/widgets/group/manage_members_sheet.dart',
    ]
    for path in files:
        if not os.path.exists(path):
            continue
        c = read(path)
        fixed = fix_ternary(c)
        if fixed != c:
            write(path, fixed)
            print(f'  Fixed ternary: {path}')

print('Fixing wave 5 errors...')
fix_member_tile()
fix_summary_tab_files()
fix_ternary_files()
print('Done.')
