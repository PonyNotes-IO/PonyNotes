#!/bin/bash

# PonyNotes 快速数据库检查脚本
# 使用方法: ./tools/quick_db_check.sh

echo "🔍 PonyNotes 数据库快速检查"
echo "============================="

# 查找数据库目录
DB_BASE_DIR="$HOME/Library/Application Support/com.appflowy.appflowy.flutter"

if [ ! -d "$DB_BASE_DIR" ]; then
    echo "❌ 未找到 PonyNotes 数据目录"
    echo "预期位置: $DB_BASE_DIR"
    exit 1
fi

echo "📂 数据目录: $DB_BASE_DIR"
echo ""

# 查找最新的数据库文件
echo "🔍 查找最新的数据库文件..."

# 查找最新修改的主数据库
LATEST_MAIN_DB=$(find "$DB_BASE_DIR" -name "flowy-database.db" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)

if [ -n "$LATEST_MAIN_DB" ]; then
    echo "📊 最新主数据库: $LATEST_MAIN_DB"
    
    # 检查数据库连接
    if sqlite3 "$LATEST_MAIN_DB" "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ 数据库连接正常"
        
        # 显示基本统计
        echo ""
        echo "📈 数据库统计:"
        
        # 用户数量
        USER_COUNT=$(sqlite3 "$LATEST_MAIN_DB" "SELECT COUNT(*) FROM user_table;" 2>/dev/null)
        echo "   👤 用户数量: ${USER_COUNT:-0}"
        
        # 工作区数量
        WORKSPACE_COUNT=$(sqlite3 "$LATEST_MAIN_DB" "SELECT COUNT(*) FROM user_workspace_table;" 2>/dev/null)
        echo "   🏢 工作区数量: ${WORKSPACE_COUNT:-0}"
        
        # 聊天会话数量
        CHAT_COUNT=$(sqlite3 "$LATEST_MAIN_DB" "SELECT COUNT(*) FROM chat_table;" 2>/dev/null)
        echo "   💬 聊天会话: ${CHAT_COUNT:-0}"
        
        # 聊天消息数量
        MESSAGE_COUNT=$(sqlite3 "$LATEST_MAIN_DB" "SELECT COUNT(*) FROM chat_message_table;" 2>/dev/null)
        echo "   📝 聊天消息: ${MESSAGE_COUNT:-0}"
        
        # 最近用户信息
        echo ""
        echo "👤 最近用户信息:"
        sqlite3 "$LATEST_MAIN_DB" "SELECT '   ID: ' || id, '   名称: ' || name, '   认证类型: ' || auth_type FROM user_table LIMIT 1;" 2>/dev/null
        
    else
        echo "❌ 数据库连接失败"
    fi
else
    echo "❌ 未找到主数据库文件"
fi

# 检查缓存数据库
echo ""
echo "🗃️ 检查缓存数据库..."

CACHE_DB=$(find "$DB_BASE_DIR" -name "cache.db" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)

if [ -n "$CACHE_DB" ]; then
    echo "📦 缓存数据库: $CACHE_DB"
    
    if sqlite3 "$CACHE_DB" "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ 缓存数据库连接正常"
        
        # 配置项数量
        CONFIG_COUNT=$(sqlite3 "$CACHE_DB" "SELECT COUNT(*) FROM kv_table;" 2>/dev/null)
        echo "   ⚙️  配置项数量: ${CONFIG_COUNT:-0}"
        
        # 显示一些关键配置
        echo ""
        echo "⚙️  关键配置:"
        
        # 外观设置
        APPEARANCE=$(sqlite3 "$CACHE_DB" "SELECT value FROM kv_table WHERE key = 'appearance_settings';" 2>/dev/null)
        if [ -n "$APPEARANCE" ]; then
            THEME=$(echo "$APPEARANCE" | python3 -c "import sys, json; data=json.loads(sys.stdin.read()); print('主题:', data.get('theme', '未知'), '| 语言:', data.get('locale', {}).get('language_code', '未知'))" 2>/dev/null)
            echo "   🎨 $THEME"
        fi
        
        # 当前会话
        SESSION=$(sqlite3 "$CACHE_DB" "SELECT value FROM kv_table WHERE key = 'appflowy_session_cache';" 2>/dev/null)
        if [ -n "$SESSION" ]; then
            SESSION_INFO=$(echo "$SESSION" | python3 -c "import sys, json; data=json.loads(sys.stdin.read()); print('用户ID:', data.get('user_id', '未知'), '| 工作区:', data.get('workspace_id', '未知')[:8] + '...')" 2>/dev/null)
            echo "   🔐 当前会话: $SESSION_INFO"
        fi
        
    else
        echo "❌ 缓存数据库连接失败"
    fi
else
    echo "❌ 未找到缓存数据库"
fi

# 检查向量数据库
echo ""
echo "🔍 检查向量数据库..."

VECTOR_DB=$(find "$DB_BASE_DIR" -name "vector.db" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)

if [ -n "$VECTOR_DB" ]; then
    echo "🧠 向量数据库: $VECTOR_DB"
    
    if sqlite3 "$VECTOR_DB" "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ 向量数据库连接正常"
        
        # 显示表数量
        TABLE_COUNT=$(sqlite3 "$VECTOR_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null)
        echo "   📊 表数量: ${TABLE_COUNT:-0}"
        
    else
        echo "❌ 向量数据库连接失败"
    fi
else
    echo "❌ 未找到向量数据库"
fi

echo ""
echo "💡 使用详细查看工具:"
echo "   python3 tools/view_database.py list"
echo "   python3 tools/view_database.py inspect \"数据库路径\""
echo ""
echo "📖 查看完整文档:"
echo "   docs/SQLite数据库查看指南.md"
