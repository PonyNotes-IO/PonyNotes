use std::env;
use std::io::{self, Write};
use pdf_extract;
use regex::Regex;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::init();

    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <pdf_path>", args[0]);
        return Ok(());
    }
    let pdf_path = &args[1];

    // 使用pdf-extract进行PDF文本提取
    match pdf_extract::extract_text(pdf_path) {
        Ok(text) => {
            if text.trim().is_empty() {
                eprintln!("No text content found in PDF");
                std::process::exit(1);
            }
            
            // 格式化处理
            let formatted_text = format_markdown(&text);
            
            // 直接输出到stdout，供Flutter捕获
            io::stdout().write_all(formatted_text.as_bytes())?;
            if !formatted_text.ends_with('\n') {
                io::stdout().write_all(b"\n")?;
            }
        }
        Err(e) => {
            eprintln!("Error extracting text from PDF: {}", e);
            std::process::exit(1);
        }
    }

    Ok(())
}

/// 格式化Markdown内容
fn format_markdown(text: &str) -> String {
    let mut result = String::new();
    
    // 按行分割内容
    let lines: Vec<&str> = text.lines().collect();
    let mut i = 0;
    let mut processed_lines = 0;
    
    while i < lines.len() {
        let line = lines[i].trim();
        
        if line.is_empty() {
            i += 1;
            continue;
        }
        
        // 检查是否是标题
        if let Some(header) = detect_title(&line) {
            result.push_str(&header);
            result.push_str("\n\n");
            i += 1;
        }
        // 检查是否是列表项
        else if let Some(list_item) = detect_list_item(&line) {
            result.push_str(&list_item);
            result.push('\n');
            i += 1;
        }
        // 处理段落内容
        else {
            let paragraph = build_paragraph(&lines, &mut i);
            if !paragraph.is_empty() {
                result.push_str(&paragraph);
                result.push_str("\n\n");
            }
        }
        
        processed_lines += 1;
        
        // 防止无限循环：如果处理的行数过多，强制停止
        if processed_lines > 10000 {
            eprintln!("Warning: Too many lines processed, stopping to prevent infinite loop");
            break;
        }
    }
    
    result
}

/// 标题检测
fn detect_title(text: &str) -> Option<String> {
    let trimmed = text.trim();
    
    // 1. 检查中文数字标题（一、二、三、）
    if let Some(captures) = Regex::new(r"^([一二三四五六七八九十]+)、(.+)$").unwrap().captures(trimmed) {
        let number = &captures[1];
        let title = &captures[2];
        return Some(format!("## {}、{}", number, title));
    }
    
    // 2. 检查阿拉伯数字标题（1. 2. 3.）
    if let Some(captures) = Regex::new(r"^(\d+)、(.+)$").unwrap().captures(trimmed) {
        let number = &captures[1];
        let title = &captures[2];
        return Some(format!("## {}、{}", number, title));
    }
    
    // 3. 检查章节标题（第X章、第X节）
    if Regex::new(r"^第[一二三四五六七八九十\d]+[章节]").unwrap().is_match(trimmed) {
        return Some(format!("## {}", trimmed));
    }
    
    // 4. 检查条款标题（第X条）
    if Regex::new(r"^第[一二三四五六七八九十\d]+条").unwrap().is_match(trimmed) {
        return Some(format!("### {}", trimmed));
    }
    
    // 5. 检查冒号标题（流程：、要求：、注意事项：）
    if trimmed.ends_with('：') && trimmed.len() < 50 {
        return Some(format!("### {}", trimmed));
    }
    
    None
}

/// 列表项检测
fn detect_list_item(text: &str) -> Option<String> {
    let trimmed = text.trim();
    
    // 1. 数字列表（1. 2. 3.）
    if let Some(captures) = Regex::new(r"^(\d+)\.\s*(.+)$").unwrap().captures(trimmed) {
        let number = &captures[1];
        let content = &captures[2];
        return Some(format!("{}. {}", number, content));
    }
    
    // 2. 中文数字列表（一. 二. 三.）
    if let Some(captures) = Regex::new(r"^([一二三四五六七八九十]+)\.\s*(.+)$").unwrap().captures(trimmed) {
        let number = &captures[1];
        let content = &captures[2];
        return Some(format!("{}. {}", number, content));
    }
    
    // 3. 项目符号列表（- * +）
    if trimmed.starts_with('-') || trimmed.starts_with('*') || trimmed.starts_with('+') {
        return Some(format!("- {}", &trimmed[1..].trim()));
    }
    
    // 4. 检测子列表项（包含缩进）
    if trimmed.starts_with("  ") || trimmed.starts_with("\t") {
        return Some(format!("  - {}", trimmed.trim()));
    }
    
    None
}

/// 构建段落
fn build_paragraph(lines: &[&str], index: &mut usize) -> String {
    let mut paragraph = String::new();
    let mut empty_line_count = 0;
    
    while *index < lines.len() {
        let line = lines[*index].trim();
        
        if line.is_empty() {
            empty_line_count += 1;
            *index += 1;
            
            // 如果连续遇到太多空行，停止构建段落
            if empty_line_count >= 2 {
                break;
            }
            continue;
        }
        
        // 重置空行计数
        empty_line_count = 0;
        
        // 如果遇到标题或列表项，停止构建段落
        if detect_title(line).is_some() || 
           detect_list_item(line).is_some() {
            break;
        }
        
        // 添加到段落
        if !paragraph.is_empty() {
            paragraph.push(' ');
        }
        paragraph.push_str(line);
        
        *index += 1;
        
        // 如果下一行是标题或列表项，停止构建段落
        if *index < lines.len() {
            let next_line = lines[*index].trim();
            if detect_title(next_line).is_some() || 
               detect_list_item(next_line).is_some() {
                break;
            }
        }
        
        // 防止无限循环：如果段落太长，强制停止
        if paragraph.len() > 1000 {
            break;
        }
    }
    
    paragraph.trim().to_string()
}