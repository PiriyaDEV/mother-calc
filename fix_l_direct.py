#!/usr/bin/env python3
"""
Targeted fixes for the 7 remaining analyze errors.

manage_members_sheet.dart:
  1. Line 157: `tabs: const [Tab(text: l.t(...)), ...]` → remove `const`
  2. _buildFriendsTab(bool isDark, ...) — add `final l = context.read<LocaleProvider>();`
  3. _buildExternalTab(bool isDark) — add `final l = context.read<LocaleProvider>();`

group_analytics_tab.dart:
  4. _buildHeroStats(...) — add `final l = context.read<LocaleProvider>();`
  5. _buildBillsBarChart(...) — add `final l = context.read<LocaleProvider>();`
  6. _buildTopItemsCard(...) — add `final l = context.read<LocaleProvider>();`
"""
import re

def fix_manage_members_sheet():
    path = 'lib/widgets/group/manage_members_sheet.dart'
    with open(path, encoding='utf-8') as f:
        content = f.read()

    # Fix 1: remove `const` from `tabs: const [Tab(text: l.t(...`
    content = content.replace(
        'tabs: const [\n                Tab(text: l.t(',
        'tabs: [\n                Tab(text: l.t('
    )

    # Fix 2: inject l into _buildFriendsTab
    # The method signature is: `Widget _buildFriendsTab(bool isDark, List<Profile> friends) {`
    content = content.replace(
        'Widget _buildFriendsTab(bool isDark, List<Profile> friends) {\n    return',
        'Widget _buildFriendsTab(bool isDark, List<Profile> friends) {\n    final l = context.read<LocaleProvider>();\n    return'
    )

    # Fix 3: inject l into _buildExternalTab
    content = content.replace(
        'Widget _buildExternalTab(bool isDark) {\n    return',
        'Widget _buildExternalTab(bool isDark) {\n    final l = context.read<LocaleProvider>();\n    return'
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Fixed: {path}')


def fix_group_analytics_tab():
    path = 'lib/widgets/group/group_analytics_tab.dart'
    with open(path, encoding='utf-8') as f:
        content = f.read()

    # Fix 4: inject l into _buildHeroStats
    # Signature spans 2 lines: `Widget _buildHeroStats(\n      double total, int itemCount, double avgPerBill, int memberCount) {`
    content = content.replace(
        '  Widget _buildHeroStats(\n      double total, int itemCount, double avgPerBill, int memberCount) {\n    final isDark = widget.isDark;',
        '  Widget _buildHeroStats(\n      double total, int itemCount, double avgPerBill, int memberCount) {\n    final l = context.read<LocaleProvider>();\n    final isDark = widget.isDark;'
    )

    # Fix 5: inject l into _buildBillsBarChart
    # Find the method and inject after opening brace
    # Pattern: `Widget _buildBillsBarChart(List<Bill> sortedBills) {`
    content = re.sub(
        r'(Widget _buildBillsBarChart\([^)]+\) \{)\n(\s+final isDark)',
        r'\1\n    final l = context.read<LocaleProvider>();\n\2',
        content
    )

    # Fix 6: inject l into _buildTopItemsCard
    content = re.sub(
        r'(Widget _buildTopItemsCard\([^)]+\) \{)\n(\s+final isDark)',
        r'\1\n    final l = context.read<LocaleProvider>();\n\2',
        content
    )

    # Also handle multi-line signatures for _buildBillsBarChart and _buildTopItemsCard
    # Try a broader pattern: any `_build*` method that uses l.t() but lacks `final l`
    # We'll do a pass over all methods
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Detect start of a _build method (single or multi-line signature)
        if re.match(r'\s+Widget _build\w+\(', line):
            # Collect until we find the opening brace
            method_start = i
            sig_lines = [line]
            j = i + 1
            # If brace not on this line, collect more lines
            while '{' not in line and j < len(lines):
                line = lines[j]
                sig_lines.append(line)
                j += 1
            # Now collect the body
            body_lines = list(sig_lines)
            depth = sum(l2.count('{') - l2.count('}') for l2 in sig_lines)
            while j < len(lines) and depth > 0:
                body_lines.append(lines[j])
                depth += lines[j].count('{') - lines[j].count('}')
                j += 1
            body = '\n'.join(body_lines)
            needs_l = 'l.t(' in body and 'final l = context' not in body
            # Output the signature lines
            for sl in sig_lines:
                result.append(sl)
            if needs_l:
                # Find the indent of the first body line after the opening brace
                # The opening brace is on the last sig line
                last_sig = sig_lines[-1]
                indent = len(last_sig) - len(last_sig.lstrip())
                inner_indent = ' ' * (indent + 4)
                result.append(f'{inner_indent}final l = context.read<LocaleProvider>();')
            i = j
            # Now output remaining body lines (already past sig)
            # Actually we need to re-output the body lines that come after sig
            body_only = body_lines[len(sig_lines):]
            for bl in body_only:
                result.append(bl)
            continue
        result.append(line)
        i += 1

    new_content = '\n'.join(result)
    if new_content != content:
        content = new_content

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Fixed: {path}')


fix_manage_members_sheet()
fix_group_analytics_tab()
print('Done.')
