mod syntax;
use crate::syntax::parser::ASTDisplay;
use crate::syntax::{parser, tokenizer};

use clap::{Parser, Subcommand};
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
    Build {
        file: PathBuf,

        #[arg(long, default_value_t = false)]
        tokens: bool,

        #[arg(long, default_value_t = false)]
        ast: bool,
    },
    LSP,
}

fn build(file_path: PathBuf, display_tokens: bool, display_ast: bool) {
    let Ok(mut file) = File::open(&file_path) else {
        log::error!("Can't open file {}", file_path.display());
        return;
    };

    let mut contents = String::new();
    let Ok(_) = file.read_to_string(&mut contents) else {
        log::error!("File not valid utf8 {}", file_path.display());
        return;
    };

    let tokens = tokenizer::lex_source(&contents);
    if display_tokens {
        log::info!("Displaying Token List");
        for token in tokens.iter() {
            log::info!("{:?}", token)
        }
    }

    let mut parser = parser::Parser::from_tokens(tokens);

    let ast = parser.parse();

    if display_ast {
        log::info!("Displaying AST");
        let mut description: Vec<String> = Vec::new();
        ast.display_ast(
            "".to_string(),
            parser::Connector::Last,
            "".to_string(),
            &mut description,
        );

        log::info!("\n{}", description.join("\n"));
    }
}

fn main() {
    let cli = Cli::parse();

    pretty_env_logger::formatted_builder()
        .filter_level(cli.logging)
        .init();

    match cli.command {
        Commands::Build { file, tokens, ast } => build(file, tokens, ast),
        Commands::LSP => println!("Lsp"),
    }
}
