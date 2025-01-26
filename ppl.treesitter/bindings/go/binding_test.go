package tree_sitter_peopl_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_peopl "github.com/tree-sitter/tree-sitter-peopl/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_peopl.Language())
	if language == nil {
		t.Errorf("Error loading PeoPl grammar")
	}
}
