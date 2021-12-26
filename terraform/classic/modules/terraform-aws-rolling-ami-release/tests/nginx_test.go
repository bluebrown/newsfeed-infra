package test

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestRollingAMIReleaseNginx(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/nginx",
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	dns := terraform.Output(t, terraformOptions, "lb_dns")

	// check that we have a correct DNS entry
	assert.Regexp(t, "^.*\\.eu-central-1\\.elb\\.amazonaws\\.com$", dns)

	// try to connect to the nginx server via the load balancer dns name
	http_helper.HTTPDoWithRetry(t, http.MethodGet, fmt.Sprintf("http://%s", dns), nil, nil, http.StatusOK, 30, time.Second*10, &tls.Config{})
}
