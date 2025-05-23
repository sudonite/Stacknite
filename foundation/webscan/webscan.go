package webscan

import (
	"context"
	"fmt"
	"io"
	"net/http"

	"github.com/sudonite/stacknite/foundation/webscan/wappalyzer"
)

type Service struct {
	wappalyzer *wappalyzer.Wappalyze
}

func New() (*Service, error) {
	wappalyzer, err := wappalyzer.New()
	if err != nil {
		return nil, fmt.Errorf("new service: %w", err)
	}

	return &Service{
		wappalyzer: wappalyzer,
	}, nil
}

func (srv *Service) Wappalyze(ctx context.Context, url string) (map[string]struct{}, error) {
	// TODO: Use ctx param in HTTP request
	resp, err := http.DefaultClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("service wappalyze http: %w", err)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("service wappalyze body: %w", err)
	}

	result := srv.wappalyzer.Fingerprint(resp.Header, data)

	return result, nil
}
