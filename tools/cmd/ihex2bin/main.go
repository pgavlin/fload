package main

import (
	"bufio"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"os"
	"sort"
	"strconv"
)

type segment struct {
	address uint16
	data    []byte
}

type parser struct {
	r        *bufio.Reader
	segments []segment
	err      error
}

func (p *parser) parseLine() bool {
	line, err := p.r.ReadString('\n')
	if err != nil && (err != io.EOF || len(line) == 0) {
		p.err = err
		return false
	}

	if len(line) < 11 || line[0] != ':' {
		p.err = fmt.Errorf("invalid line")
		return false
	}
	line = line[1:]

	_, err = strconv.ParseUint(line[:2], 16, 8)
	if err != nil {
		p.err = err
		return false
	}
	line = line[2:]

	address, err := strconv.ParseUint(line[:4], 16, 16)
	if err != nil {
		p.err = err
		return false
	}
	line = line[4:]

	recordType, err := strconv.ParseUint(line[:2], 16, 8)
	if err != nil {
		p.err = err
		return false
	}
	line = line[2:]

	switch recordType {
	case 0:
		data, err := hex.DecodeString(line[:len(line)-3])
		if err != nil {
			p.err = err
			return false
		}
		p.segments = append(p.segments, segment{
			address: uint16(address),
			data:    data,
		})
		return true
	case 1:
		p.err = nil
		return false
	default:
		p.err = fmt.Errorf("unsupported record type %v", recordType)
		return false
	}
}

func parseIntelHex(r io.Reader) ([]byte, error) {
	p := parser{r: bufio.NewReader(r)}
	for p.parseLine() {
	}
	if p.err != nil || len(p.segments) == 0 {
		return nil, p.err
	}

	sort.Slice(p.segments, func(i, j int) bool { return p.segments[i].address < p.segments[j].address })
	first, last := p.segments[0], p.segments[len(p.segments)-1]
	start, end := first.address, last.address+uint16(len(last.data))

	bytes := make([]byte, end-start)
	for _, s := range p.segments {
		copy(bytes[s.address-start:], s.data)
	}
	return bytes, nil
}

func main() {
	bin, err := parseIntelHex(os.Stdin)
	if err != nil {
		log.Fatal(err)
	}

	_, err = os.Stdout.Write(bin)
	if err != nil {
		log.Fatal(err)
	}
}
