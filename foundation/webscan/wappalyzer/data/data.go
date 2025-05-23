package data

import (
	_ "embed"
	"encoding/json"
	"strconv"
	"sync"
)

var (
	//go:embed fingerprints.json
	fingerprints string
	//go:embed categories.json
	cateogriesData string

	syncOnce          sync.Once
	categoriesMapping map[int]categoryItem
)

func init() {
	syncOnce.Do(func() {
		categoriesMapping = make(map[int]categoryItem)

		var categories map[string]categoryItem
		if err := json.Unmarshal([]byte(cateogriesData), &categories); err != nil {
			panic(err)
		}
		for category, data := range categories {
			parsed, _ := strconv.Atoi(category)
			categoriesMapping[parsed] = data
		}
	})
}

func GetRawFingerprints() string {
	return fingerprints
}

func GetRawCategories() map[int]categoryItem {
	return categoriesMapping
}

type categoryItem struct {
	Name     string `json:"name"`
	Priority int    `json:"priority"`
}
