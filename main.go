package main

import (
	"flag"
	"fmt"
	"io"
	"log"

	"github.com/deshboard/boilerplate-grpc-client/protobuf"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
)

func main() {
	var (
		serverAddr = flag.String("server", "localhost:8080", "gRPC server address.")
		stream     = flag.Bool("stream", false, "Stream gRPC server.")
	)
	flag.Parse()

	conn, err := grpc.Dial(*serverAddr, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := protobuf.NewBoilerplateClient(conn)

	if *stream {
		str, err := c.StreamingMethod(context.Background(), &protobuf.Request{})
		if err != nil {
			log.Fatalf("method call failed: %v", err)
		}

		for {
			_, err = str.Recv()
			if err == io.EOF {
				break
			}
			if err != nil {
				log.Fatal(err)
			}
			fmt.Println("ok")
		}
	} else {
		_, err = c.Method(context.Background(), &protobuf.Request{})
		if err != nil {
			log.Fatalf("method call failed: %v", err)
		} else {
			log.Println("ok")
		}
	}
}
