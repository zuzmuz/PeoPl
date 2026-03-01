use std::fmt;

enum Connector {
    Last,
    NotLast,
}

enum TerminalColor {
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,

    // Bright colors
    BrightBlack,
    BrightRed,
    BrightGreen,
    BrightYellow,
    BrightBlue,
    BrightMagenta,
    BrightCyan,
    BrightWhite,

    // Reset
    Reset,

    // Background colors
    BgRed,
    BgGreen,
    BgYellow,
    BgBlue,

    // Text styles
    Bold,
    Dim,
    Italic,
    Underline,
}
impl TerminalColor {
    fn ansi(&self) -> &'static str {
        match self {
            Self::Black => "\u{001B}[30m",
            Self::Red => "\u{001B}[31m",
            Self::Green => "\u{001B}[32m",
            Self::Yellow => "\u{001B}[33m",
            Self::Blue => "\u{001B}[34m",
            Self::Magenta => "\u{001B}[35m",
            Self::Cyan => "\u{001B}[36m",
            Self::White => "\u{001B}[37m",

            Self::BrightBlack => "\u{001B}[90m",
            Self::BrightRed => "\u{001B}[91m",
            Self::BrightGreen => "\u{001B}[92m",
            Self::BrightYellow => "\u{001B}[93m",
            Self::BrightBlue => "\u{001B}[94m",
            Self::BrightMagenta => "\u{001B}[95m",
            Self::BrightCyan => "\u{001B}[96m",
            Self::BrightWhite => "\u{001B}[97m",

            Self::Reset => "\u{001B}[0m",

            Self::BgRed => "\u{001B}[41m",
            Self::BgGreen => "\u{001B}[42m",
            Self::BgYellow => "\u{001B}[43m",
            Self::BgBlue => "\u{001B}[44m",

            Self::Bold => "\u{001B}[1m",
            Self::Dim => "\u{001B}[2m",
            Self::Italic => "\u{001B}[3m",
            Self::Underline => "\u{001B}[4m",
        }
    }
}

trait Colored {
    fn colored(self, color: TerminalColor) -> Self;
}

impl Colored for String {
    fn colored(self, color: TerminalColor) -> Self {
        format!("{}{}{}", color.ansi(), self, TerminalColor::Reset.ansi())
    }
}

impl Connector {
    pub fn raw(&self) -> String {
        match self {
            Self::Last => "└─ ".to_string().colored(TerminalColor::BrightBlack),

            Self::NotLast => {
                "├─ ".to_string().colored(TerminalColor::BrightBlack)
            }
        }
    }
    pub fn child_prefix(&self) -> String {
        match self {
            Self::Last => "   ".to_string().colored(TerminalColor::BrightBlack),
            Self::NotLast => {
                "│  ".to_string().colored(TerminalColor::BrightBlack)
            }
        }
    }
}


trait ASTFormattableNode {
    fn formatAST(
        prefix: String,
        connector: Connector,
        extra: String,
        description: &mut Vec<String>
    );
}

impl fmt::Display for ASTFormattableNode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        todo!()
    }
}
