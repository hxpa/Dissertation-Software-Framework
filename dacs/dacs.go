// Script to define the DACs configuration
// Author: Huthayfa Patel

package main

// Imports required libraries
import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"path/filepath"

	v1 "k8s.io/api/admission/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Defines global variables
var (
	port     = os.Getenv("WEBHOOK_PORT")                      
	allowRun = GetEnvDefault("ALLOW_RUN", "false") == "true"   
	tlsDir   = os.Getenv("TLS_DIR")                             
)


// Defines JSON content type
const (
	jsonContentType = "application/json" 
)

// Defines main function of script
func main() {
	// Defines a new ServeMux used to route incoming HTTP requests
	mux := http.NewServeMux()

	// Defines a handler for incoming requests for the validate endpoint
	mux.Handle("/validate", validateHandler())

	// Defines a HTTP server using the above config
	server := &http.Server{
		Handler: mux,                      
		Addr:    ":" + port,                 
	}

	// Defines paths of the TLS cert and key files
	certFile := filepath.Join(tlsDir, "tls.crt")
	keyFile := filepath.Join(tlsDir, "tls.key")

	// Defines a message log for debugging
	log.Println("Webhook server is listening")

	// Starts the HTTP server using the above config 
	log.Fatal(server.ListenAndServeTLS(certFile, keyFile))
}

// Defines the handler function 
func validateHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Defines a message log for debugging
		log.Println("Incoming request...")

		// Checks if the request method is POST
		// If not, error
		if r.Method != http.MethodPost {
			w.WriteHeader(http.StatusMethodNotAllowed)
			w.Write(responseBody("Invalid method %s, only POST requests are allowed", r.Method))
			return
		}

		// Reads the body of the POST request 
		// If there is no body, erorr
		body, err := io.ReadAll(r.Body)
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			w.Write(responseBody("Could not read body: %v", err))
			return
		}

		// Checks if the content type is JSON
		// If not, error
		if contentType := r.Header.Get("Content-Type"); contentType != jsonContentType {
			w.WriteHeader(http.StatusBadRequest)
			w.Write(responseBody("Unsupported content type %s, only %s is supported", contentType, jsonContentType))
			return
		}

		// Unmarshals the POST request body into an admission review object
		// If any issuesm error
		var review v1.AdmissionReview
		if err := json.Unmarshal(body, &review); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			w.Write(responseBody("Could not deserialize request: %v", err))
			return
		}

		// Creates an an admission review response from the admission review object
		admissionReviewResponse := v1.AdmissionReview{
			TypeMeta: review.TypeMeta,
			Response: &v1.AdmissionResponse{
				UID:     review.Request.UID,
				Allowed: true,
			},
		}

		// Checks if the pod namespace is dissertation
		// If not, error
		if review.Request.Namespace != "dissertation" {
			w.WriteHeader(http.StatusOK)
			w.Write(responseBody("Admission not required for namespace %s", review.Request.Namespace))
			return
		}

		// Unmarshals the request object into a pod object
		// If any issues, error
		raw := review.Request.Object.Raw
		pod := corev1.Pod{}
		if err := json.Unmarshal(raw, &pod); err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write(responseBody("Could not unmarshal pod spec: %v", err))
			return
		}

		// Checks if the pod base image is  ubuntu:latest
		// If so, error
		for _, container := range pod.Spec.Containers {
			if strings.Contains(container.Image, "ubuntu:latest") {
				// Deny admission and set a failure message
				admissionReviewResponse.Response.Allowed = false
				admissionReviewResponse.Response.Result = &metav1.Status{
					Status:  "Failure",
					Message: "Pods cannot use the ubuntu:latest base image",
				}
				break
			}
		}

		// Marshals the admission review response into JSON
		response, err := json.Marshal(admissionReviewResponse)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write(responseBody("Could not marshal JSON response: %v", err))
			return
		}

		// Writes the JSON response
		w.WriteHeader(http.StatusOK)
		w.Write(response)
	})
}

// Defines the response body function
func responseBody(format string, args ...interface{}) []byte {
	// Formats the message
	msg := fmt.Sprintf(format, args...)

	// Logs any errors for debugging
	log.Println("[ERROR]: " + msg)

	// Converts the message to bytes
	return []byte(msg)
}

// Defines the get env var function
func GetEnvDefault(key, def string) string {
	// Gets the env var value and returns if not set
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

