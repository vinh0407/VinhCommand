#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Manager, Runtime, WebviewWindowBuilder,
};
use tauri_plugin_dialog::DialogExt;
use tauri_plugin_fs::FsExt;
use tauri_plugin_shell::ShellExt;
use tauri_plugin_process::ProcessExt;
use tauri_plugin_opener::OpenerExt;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_process::init())
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            setup_tray(app.handle().clone())?;
            setup_window(app.handle().clone())?;
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            greet,
            get_app_version,
            open_external_url,
            read_file,
            write_file,
            list_dir,
            create_dir,
            remove_file,
            run_command,
            get_env,
            set_env
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

fn setup_tray(app_handle: AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    let show_item = MenuItem::with_id(app_handle, "show", "Show", true, None::<&str>)?;
    let quit_item = MenuItem::with_id(app_handle, "quit", "Quit", true, None::<&str>)?;
    let menu = Menu::with_items(app_handle, &[&show_item, &quit_item])?;

    let _tray = TrayIconBuilder::new()
        .icon(app_handle.default_window_icon().unwrap().clone())
        .menu(&menu)
        .on_menu_event(|app, event| match event.id.as_ref() {
            "show" => {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.show();
                    let _ = window.set_focus();
                }
            }
            "quit" => {
                app.exit(0);
            }
            _ => {}
        })
        .on_tray_icon_event(|tray, event| {
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                if let Some(window) = tray.app_handle().get_webview_window("main") {
                    let _ = window.show();
                    let _ = window.set_focus();
                }
            }
        })
        .build(app_handle)?;

    Ok(())
}

fn setup_window(app_handle: AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    if let Some(window) = app_handle.get_webview_window("main") {
        window.set_title("VinhCommand")?;
    }
    Ok(())
}

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! Welcome to VinhCommand.", name)
}

#[tauri::command]
fn get_app_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

#[tauri::command]
async fn open_external_url(url: String) -> Result<(), String> {
    tauri::plugin_opener::open_url(url, None::<&str>).await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn read_file(path: String) -> Result<String, String> {
    std::fs::read_to_string(path).map_err(|e| e.to_string())
}

#[tauri::command]
async fn write_file(path: String, content: String) -> Result<(), String> {
    std::fs::write(path, content).map_err(|e| e.to_string())
}

#[tauri::command]
async fn list_dir(path: String) -> Result<Vec<DirEntry>, String> {
    let entries = std::fs::read_dir(path).map_err(|e| e.to_string())?;
    let mut result = Vec::new();
    for entry in entries {
        let entry = entry.map_err(|e| e.to_string())?;
        let metadata = entry.metadata().map_err(|e| e.to_string())?;
        result.push(DirEntry {
            name: entry.file_name().to_string_lossy().to_string(),
            path: entry.path().to_string_lossy().to_string(),
            is_dir: metadata.is_dir(),
            size: if metadata.is_file() { Some(metadata.len()) } else { None },
            modified: metadata.modified().ok().map(|t| t.duration_since(std::time::UNIX_EPOCH).unwrap().as_secs()),
        });
    }
    Ok(result)
}

#[tauri::command]
async fn create_dir(path: String) -> Result<(), String> {
    std::fs::create_dir_all(path).map_err(|e| e.to_string())
}

#[tauri::command]
async fn remove_file(path: String) -> Result<(), String> {
    std::fs::remove_file(path).map_err(|e| e.to_string())
}

#[tauri::command]
async fn run_command(command: String, args: Vec<String>, cwd: Option<String>) -> Result<CommandOutput, String> {
    use std::process::Stdio;
    use tokio::process::Command as TokioCommand;

    let mut cmd = TokioCommand::new(&command);
    cmd.args(&args);
    cmd.stdout(Stdio::piped());
    cmd.stderr(Stdio::piped());
    if let Some(cwd) = cwd {
        cmd.current_dir(cwd);
    }

    let output = cmd.output().await.map_err(|e| e.to_string())?;

    Ok(CommandOutput {
        stdout: String::from_utf8_lossy(&output.stdout).to_string(),
        stderr: String::from_utf8_lossy(&output.stderr).to_string(),
        status: output.status.code().unwrap_or(-1),
    })
}

#[tauri::command]
fn get_env(key: String) -> Option<String> {
    std::env::var(key).ok()
}

#[tauri::command]
fn set_env(key: String, value: String) {
    std::env::set_var(key, value);
}

#[derive(serde::Serialize)]
struct DirEntry {
    name: String,
    path: String,
    is_dir: bool,
    size: Option<u64>,
    modified: Option<u64>,
}

#[derive(serde::Serialize)]
struct CommandOutput {
    stdout: String,
    stderr: String,
    status: i32,
}