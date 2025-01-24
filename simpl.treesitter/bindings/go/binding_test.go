package tree_sitter_simpl_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_simpl "github.com/tree-sitter/tree-sitter-simpl/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_simpl.Language())
	if language == nil {
		t.Errorf("Error loading Simpl grammar")
	}
}
