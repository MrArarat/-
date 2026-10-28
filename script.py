import os
import sys
from pathlib import Path

def print_directory_tree(root_path, prefix="", is_last=True, output_lines=None):
    """Рекурсивно строит дерево директорий"""
    if output_lines is None:
        output_lines = []
    
    # Получаем все элементы в текущей директории
    try:
        items = sorted([p for p in root_path.iterdir() if not p.name.startswith('.') and p.name not in ['script.py', 'structure.txt', '.qmake.stash']])
    except PermissionError:
        return output_lines
    
    # Разделяем на папки и файлы
    dirs = [p for p in items if p.is_dir()]
    files = [p for p in items if p.is_file()]
    
    # Сортируем: сначала папки, потом файлы
    sorted_items = sorted(dirs, key=lambda x: x.name) + sorted(files, key=lambda x: x.name)
    
    for i, item in enumerate(sorted_items):
        is_last_item = (i == len(sorted_items) - 1)
        
        # Определяем символы для отображения
        if is_last_item:
            branch = "└── "
            next_prefix = prefix + "    "
        else:
            branch = "├── "
            next_prefix = prefix + "│   "
        
        # Добавляем элемент
        if item.is_dir():
            output_lines.append(f"{prefix}{branch}📁 {item.name}/")
            print_directory_tree(item, next_prefix, is_last_item, output_lines)
        else:
            output_lines.append(f"{prefix}{branch}📄 {item.name}")
    
    return output_lines

def get_file_contents(root_path, output_lines=None):
    """Собирает содержимое всех файлов"""
    if output_lines is None:
        output_lines = []
    
    for item in root_path.rglob('*'):
        if item.is_file() and not item.name.startswith('.') and item.name not in ['script.py', 'structure.txt', '.qmake.stash']:
            rel_path = item.relative_to(root_path.parent) if root_path.parent else item.relative_to(root_path)
            
            try:
                with open(item, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if content.strip():
                        output_lines.append(f"\n{'=' * 60}")
                        output_lines.append(f"ФАЙЛ: {rel_path}")
                        output_lines.append(f"{'=' * 60}")
                        output_lines.append(content)
                        output_lines.append(f"{'=' * 60}\n")
                    else:
                        output_lines.append(f"\n📄 {rel_path} - (пустой файл)")
            except (UnicodeDecodeError, PermissionError):
                output_lines.append(f"\n📄 {rel_path} - (бинарный файл или недоступен для чтения)")
            except Exception as e:
                output_lines.append(f"\n📄 {rel_path} - (ошибка чтения: {str(e)})")
    
    return output_lines

def main():
    root_dir = "." if len(sys.argv) < 2 else sys.argv[1]
    output_file = "structure.txt" if len(sys.argv) < 3 else sys.argv[2]
    
    root_path = Path(root_dir).resolve()
    
    if not root_path.exists() or not root_path.is_dir():
        print(f"Ошибка: {root_path} не существует или не является директорией!")
        return
    
    # Собираем вывод
    all_lines = []
    
    # Заголовок
    all_lines.append("=" * 80)
    all_lines.append(f"СТРУКТУРА ПАПКИ И СОДЕРЖИМОЕ ФАЙЛОВ")
    all_lines.append(f"Корневая директория: {root_path}")
    all_lines.append(f"Дата генерации: {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    all_lines.append("=" * 80)
    all_lines.append("")
    
    # Структура директорий
    all_lines.append("📂 СТРУКТУРА ДИРЕКТОРИЙ:")
    all_lines.append("")
    all_lines.append(f"{root_path.name}/")
    
    # Рисуем дерево
    tree_lines = print_directory_tree(root_path, "", True, [])
    for line in tree_lines:
        all_lines.append(line)
    
    all_lines.append("")
    all_lines.append("=" * 80)
    all_lines.append("")
    
    # Содержимое файлов
    all_lines.append("📄 СОДЕРЖИМОЕ ФАЙЛОВ:")
    all_lines.append("")
    
    # Собираем содержимое файлов
    content_lines = get_file_contents(root_path, [])
    for line in content_lines:
        all_lines.append(line)
    
    # Записываем в файл
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(all_lines))
    
    print(f"✅ Структура и содержимое успешно записаны в файл: {output_file}")

if __name__ == "__main__":
    main()