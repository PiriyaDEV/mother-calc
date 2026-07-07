#!/usr/bin/env python3
"""
Fix errors introduced by wave 4 i18n wiring:
1. `l` undefined in non-build methods (State methods, dialog callbacks, etc.)
2. `const` on constructors/lists that now contain l.t() calls
3. Broken validator: `? 'x' : null` → `: l.t('x') : null` (wrong syntax)
4. `const _NavDef(...)` with l.t() inside
"""
import re, os

LOCALE_IMPORT = "import 'package:kidtang_flutter/providers/locale_provider.dart';"
PROVIDER_IMPORT = "import 'package:provider/provider.dart';"

def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read()

def write(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ── 1. main_shell.dart: const _NavDef → _NavDef ──────────────────────────────
def fix_main_shell():
    path = 'lib/screens/shared/main_shell.dart'
    c = read(path)
    # Remove const from _NavDef constructors that now have l.t() calls
    c = re.sub(r'const (_NavDef\()', r'\1', c)
    write(path, c)
    print(f'Fixed: {path}')

# ── 2. notifications_screen.dart: const EmptyState → remove const ─────────────
def fix_notifications():
    path = 'lib/screens/friend/notifications_screen.dart'
    c = read(path)
    # Remove `const` before widget constructors that now have l.t() args
    # Lines 241-242: `const EmptyState(` or similar
    c = re.sub(r'const (EmptyState\()', r'\1', c)
    # Also inject l into build() if not already there
    write(path, c)
    print(f'Fixed: {path}')

# ── 3. create_bill_screen.dart: const FormSectionLabel → remove const ─────────
def fix_create_bill():
    path = 'lib/screens/bill/create_bill_screen.dart'
    c = read(path)
    # Remove `const` before FormSectionLabel that now has l.t() args
    c = re.sub(r'const (FormSectionLabel\()', r'\1', c)
    write(path, c)
    print(f'Fixed: {path}')

# ── 4. create_group_screen.dart: const FormSectionLabel → remove const ────────
def fix_create_group():
    path = 'lib/screens/group/create_group_screen.dart'
    c = read(path)
    c = re.sub(r'const (FormSectionLabel\()', r'\1', c)
    write(path, c)
    print(f'Fixed: {path}')

# ── 5. onboarding_screen.dart: broken validator syntax ────────────────────────
def fix_onboarding():
    path = 'lib/screens/shared/onboarding_screen.dart'
    c = read(path)
    # The script produced: `? 'x' : null` → `: l.t('x') : null`
    # which is wrong. Fix: `(v == null || v.trim().isEmpty) ? l.t('x') : null`
    # The broken line looks like: `(v == null || v.trim().isEmpty): l.t('onboarding_display_name_required') : null`
    c = c.replace(
        "(v == null || v.trim().isEmpty): l.t('onboarding_display_name_required') : null",
        "(v == null || v.trim().isEmpty) ? l.t('onboarding_display_name_required') : null"
    )
    write(path, c)
    print(f'Fixed: {path}')

# ── 6. Inject `l` into methods that use l.t() but lack it ─────────────────────
# For StatefulWidget State classes, `context` is available as a field.
# We need to inject `final l = context.read<LocaleProvider>();` at the top of
# each method body that uses l.t() but doesn't have it.

def inject_l_in_methods(content):
    """
    Inject `final l = context.read<LocaleProvider>();` into:
    - Any method body (including async) that uses l.t() but doesn't have `final l`
    - Handles: void _x(), Future<void> _x(), Future<T> _x(), void _x() async
    - Also handles: _showConfirmDialog(context, ...) { ... }
    """
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Match any method-like line that ends with `{` (possibly async)
        # and is NOT a build() method (already handled)
        is_method_start = (
            re.match(r'\s+(void|Future|String\??|bool|Widget|dynamic)\s+\w+\s*\(', line) or
            re.match(r'\s+\w+\s+_\w+\s*\(', line)
        )
        is_build = re.match(r'\s*Widget build\(BuildContext context\)', line)
        ends_with_brace = line.rstrip().endswith('{')

        if is_method_start and not is_build and ends_with_brace:
            indent = len(line) - len(line.lstrip())
            # Collect body
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
            # Output remaining body lines
            for bl in body_lines[1:]:
                result.append(bl)
            continue
        result.append(line)
        i += 1
    return '\n'.join(result)

def inject_l_in_callbacks(content):
    """
    Inject l into anonymous function callbacks like:
    onPressed: () { ... l.t(...) ... }
    onPressed: () async { ... l.t(...) ... }
    These are harder — we look for `() {` or `() async {` patterns
    """
    # This is complex; instead, ensure the enclosing build() or method has l
    # The real fix is to ensure the State's build() has l declared
    return content

def fix_l_in_file(path):
    if not os.path.exists(path):
        return
    c = read(path)
    if 'l.t(' not in c:
        return
    new_c = inject_l_in_methods(c)
    if new_c != c:
        write(path, new_c)
        print(f'  Injected l into methods: {path}')

# Files with `l` undefined in non-build methods
FILES_NEEDING_L = [
    'lib/screens/bill/create_bill_screen.dart',
    'lib/screens/friend/friends_screen.dart',
    'lib/screens/friend/notifications_screen.dart',
    'lib/screens/group/create_group_screen.dart',
    'lib/screens/me/me_screen.dart',
    'lib/screens/me/profile_screen.dart',
    'lib/screens/shared/onboarding_screen.dart',
    'lib/screens/shared/main_shell.dart',
]

# ── Run ───────────────────────────────────────────────────────────────────────
fix_main_shell()
fix_notifications()
fix_create_bill()
fix_create_group()
fix_onboarding()

for path in FILES_NEEDING_L:
    fix_l_in_file(path)

print('Done.')
