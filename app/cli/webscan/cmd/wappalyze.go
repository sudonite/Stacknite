package cmd

import (
	"context"
	"fmt"
	"log"

	"github.com/spf13/cobra"
	"github.com/sudonite/stacknite/foundation/webscan"
)

var url string

var wappalyzeCmd = &cobra.Command{
	Use:   "wappalyze",
	Short: "Analyze technologies used on a website",
	RunE: func(cmd *cobra.Command, args []string) error {
		url, err := cmd.Flags().GetString("url")
		if err != nil || url == "" {
			return fmt.Errorf("required flag \"url\" not set")
		}
		fmt.Printf("Analyzing: %s\n", url)

		webscan, err := webscan.New()
		if err != nil {
			log.Fatal(err)
		}

		ctx := context.Background()

		result, err := webscan.Wappalyze(ctx, url)
		if err != nil {
			log.Fatal(err)
		}

		fmt.Println(result)

		return nil
	},
}

func init() {
	wappalyzeCmd.Flags().StringP("url", "u", "", "URL to analyze (required)")
	wappalyzeCmd.MarkFlagRequired("name") // <-- Enforces that --name/-n is required

	rootCmd.AddCommand(wappalyzeCmd)
}
