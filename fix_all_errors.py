#!/usr/bin/env python3
"""
Fix all remaining compile errors from i18n wiring:
1. `const InputDecoration(hintText: l.t(...))` → remove const
2. `const FormSectionLabel(...)` with l.t() → remove const
3. `const SizedBox(...)` / `const Text(...)` / `const Icon(...)` etc. with l.t() → remove const
4. `const EmptyState(...)` with l.t() → remove const
5. `const InputDecoration(...)` with l.t() → remove const
6. `l` undefined in non-build methods → inject `final l = context.read<LocaleProvider>();`
7. Broken validator: `(cond): l.t('x') : null` → `(cond) ? l.t('x') : null`
"""
import re, os, sys

def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()

def write(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def fix_const_with_lt(content):
    """Remove `const` keyword before any constructor call that contains l.t(...)"""
    # Match: const SomeWidget( ... l.t( ... ) ... )
    # Strategy: find all `const ` followed by an identifier+( on the same line that also has l.t(
    lines = content.split('\n')
    result = []
    for line in lines:
        if 'const ' in line and 'l.t(' in line:
            # Remove `const ` before any constructor/class name
            # Pattern: `const ClassName(` or `const [` 
            line = re.sub(r'\bconst\s+(?=[A-Z_\[])', '', line)
            # Also handle `const InputDecoration(` etc (lowercase first letter edge cases)
            line = re.sub(r'\bconst\s+(InputDecoration\()', r'\1', line)
        result.append(line)
    return '\n'.join(result)

def fix_broken_validator(content):
    """Fix: `(cond): l.t('x') : null` → `(cond) ? l.t('x') : null`"""
    # Pattern produced by bad script: `isEmpty): l.t(` 
    content = re.sub(r'\)\s*:\s*(l\.t\()', r') ? \1', content)
    return content

def inject_l_in_non_build_methods(content):
    """
    For any method body that uses l.t() but doesn't have `final l =`,
    inject `final l = context.read<LocaleProvider>();` as first statement.
    
    Handles:
    - void _method() { ... }
    - Future<void> _method() async { ... }
    - void _method() async { ... }
    - Any method starting with underscore (private)
    """
    lines = content.split('\n')
    result = []
    i = 0
    
    # Method signature patterns (non-build methods)
    method_start_re = re.compile(
        r'^(\s+)((?:Future<[^>]+>|void|String\??|bool|int|double|dynamic|Widget)\s+_\w+\s*\([^)]*\)(?:\s+async)?)\s*\{',
    )
    
    while i < len(lines):
        line = lines[i]
        m = method_start_re.match(line)
        
        if m:
            indent = m.group(1)
            # Collect the full method body to check if it uses l.t()
            body_lines = [line]
            depth = line.count('{') - line.count('}')
            j = i + 1
            while j < len(lines) and depth > 0:
                body_lines.append(lines[j])
                depth += lines[j].count('{') - lines[j].count('}')
                j += 1
            
            body_text = '\n'.join(body_lines)
            needs_l = 'l.t(' in body_text and 'final l = context' not in body_text
            
            result.append(line)
            if needs_l:
                inner_indent = indent + '    '
                result.append(f'{inner_indent}final l = context.read<LocaleProvider>();')
            
            # Add remaining body lines
            for bl in body_lines[1:]:
                result.append(bl)
            i = j
            continue
        
        result.append(line)
        i += 1
    
    return '\n'.join(result)

def fix_file(path):
    if not os.path.exists(path):
        print(f'  SKIP (not found): {path}')
        return
    
    original = read(path)
    content = original
    
    content = fix_const_with_lt(content)
    content = fix_broken_validator(content)
    content = inject_l_in_non_build_methods(content)
    
    if content != original:
        write(path, content)
        print(f'  Fixed: {path}')
    else:
        print(f'  No changes: {path}')

# All files that had i18n wiring applied
FILES = [
    'lib/screens/bill/create_bill_screen.dart',
    'lib/screens/bill/bills_screen.dart',
    'lib/screens/bill/bill_detail_screen.dart',
    'lib/screens/friend/friends_screen.dart',
    'lib/screens/friend/notifications_screen.dart',
    'lib/screens/group/create_group_screen.dart',
    'lib/screens/group/group_detail_screen.dart',
    'lib/screens/group/groups_screen.dart',
    'lib/screens/home/home_screen.dart',
    'lib/screens/me/me_screen.dart',
    'lib/screens/me/profile_screen.dart',
    'lib/screens/shared/onboarding_screen.dart',
    'lib/screens/shared/main_shell.dart',
    'lib/screens/shared/login_screen.dart',
    'lib/widgets/bill/item_form_sheet.dart',
    'lib/widgets/bill/member_form_sheet.dart',
    'lib/widgets/friends/add_friend_panel.dart',
    'lib/widgets/friends/pending_requests_card.dart',
    'lib/widgets/friends/friend_row.dart',
    'lib/widgets/friends/empty_friends_state.dart',
    'lib/widgets/home/home_empty_state.dart',
    'lib/widgets/home/hero_balance_card.dart',
    'lib/widgets/home/recent_bills_list.dart',
    'lib/widgets/group/manage_members_sheet.dart',
    'lib/widgets/shared/skeleton_loader.dart',
]

print('Fixing all i18n errors...')
for f in FILES:
    fix_file(f)
print('Done.')
