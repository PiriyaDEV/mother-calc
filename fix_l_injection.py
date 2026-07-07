#!/usr/bin/env python3
"""
Fix remaining analyze errors:
1. Inject `final l = context.read<LocaleProvider>();` into any method
   (not just build()) that has BuildContext context param and uses l.t()
   but doesn't already have the declaration.
2. Fix `const` before widget constructors that now have non-const args.
"""
import re, os

def inject_l_into_all_methods(content):
    """
    Scan every method signature that has `BuildContext context` as a parameter
    and contains `l.t(` in its body but lacks `final l = context`.
    Inject `final l = context.read<LocaleProvider>();` as the first statement.
    """
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Match any method/function that has BuildContext context in its signature
        # Covers: `Widget build(...)`, `Widget _buildXxx(...)`, `void _buildXxx(...)`, etc.
        # The opening brace must be on the same line.
        if re.search(r'BuildContext context', line) and line.rstrip().endswith('{'):
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


def fix_const_invocations(content):
    """
    Remove `const` keyword before widget constructor calls that now contain
    non-const expressions (l.t(...) calls).
    Strategy: find lines with `const SomeWidget(` where the widget's argument
    block contains `l.t(` and remove the `const`.
    Simple approach: remove `const ` before any identifier that is followed by
    `(` on a line that is inside a block containing `l.t(`.
    
    Simpler targeted approach: just remove `const ` before known problematic patterns.
    """
    # Remove `const` before InputDecoration, hintText, etc. that have l.t()
    # The safest approach: remove `const` from any line where the same line
    # or the next few lines contain l.t(
    lines = content.split('\n')
    result = []
    for i, line in enumerate(lines):
        # If this line has `const SomeWidget(` and within the next 5 lines there's l.t(
        if 'const ' in line and '(' in line:
            # Check if this const is problematic by looking ahead
            lookahead = '\n'.join(lines[i:min(i+10, len(lines))])
            if 'l.t(' in lookahead:
                # Remove `const ` before widget-like identifiers (PascalCase or known widgets)
                line = re.sub(r'\bconst\s+(?=[A-Z])', '', line)
        result.append(line)
    return '\n'.join(result)


def process(path):
    if not os.path.exists(path):
        print(f'  SKIP (not found): {path}')
        return
    with open(path, encoding='utf-8') as f:
        content = f.read()
    original = content
    content = inject_l_into_all_methods(content)
    content = fix_const_invocations(content)
    if content != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'  Fixed: {path}')
    else:
        print(f'  No change: {path}')


FILES = [
    'lib/widgets/group/group_analytics_tab.dart',
    'lib/widgets/group/manage_members_sheet.dart',
]

for f in FILES:
    process(f)

print('Done.')
