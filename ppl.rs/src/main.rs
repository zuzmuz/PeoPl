mod syntax;
use crate::syntax::parser::ASTDisplay;
use crate::syntax::{parser, tokenizer};

use clap::{Parser, Subcommand};
use colored::{self, Colorize};
use log;
use pretty_env_logger;
use std::fs::File;
use std::io::Read;
use std::path::PathBuf;

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    /// Optional name to operate on
    // name: Option<String>,
    //
    // /// Sets a custom config file
    // #[arg(short, long, value_name = "FILE")]
    // config: Option<PathBuf>,
    //
    /// Logging level
    #[arg(short, long, default_value_t = log::LevelFilter::Info)]
    logging: log::LevelFilter,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// print ast of file
    AST {
        file: PathBuf,
    },
    LSP,
}

fn ast(file_path: PathBuf) {
    let Ok(mut file) = File::open(&file_path) else {
        log::error!("Can't open file {}", file_path.display());
        return;
    };

    let mut contents = String::new();
    let Ok(result) = file.read_to_string(&mut contents) else {
        log::error!("File not valid utf8 {}", file_path.display());
        return;
    };

    let mut parser = parser::Parser::new(&contents);

    let ast = parser.parse();

    let mut description: Vec<String> = Vec::new();
    ast.display_ast(
        "".to_string(),
        parser::Connector::Last,
        "".to_string(),
        &mut description,
    );

    log::info!("\n{}", description.join("\n"));
}

fn main() {
    let cli = Cli::parse();

    pretty_env_logger::formatted_builder()
        .filter_level(cli.logging)
        .init();

    match cli.command {
        Commands::AST { file } => ast(file),
        Commands::LSP => println!("Lsp"),
    }
}
