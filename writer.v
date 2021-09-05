module bufwriter

import io

// Writer implements buffering for an io.Writer object.
// If an error occurs writing to a Writer, no more data will be
// accepted and all subsequent writes, and flush, will return the error.
// After all data has been written, the client should call the
// flush method to guarantee all data has been forwarded to
// the underlying io.Writer.
pub struct Writer {
mut:
	writer  io.Writer
	buf     []byte
	n       int // the number of bytes that have been written into the current buffer.
	lasterr string
}

// Config are options that can be given to a writer
pub struct Config {
	writer io.Writer
	cap    int = 4096
}

// new returns a new Writer whose buffer has the default size.
pub fn new(o Config) &Writer {
	if o.cap < 0 {
		panic('new should be called with a non-negative `cap`')
	}

	if o.writer is Writer {
		if o.writer.buf.len >= o.cap {
			return o.writer
		}
	}

	return &Writer{
		writer: o.writer
		buf: []byte{len: o.cap, cap: o.cap}
	}
}

// flush writes any buffered data to the underlying io.Writer.
pub fn (mut b Writer) flush() ? {
	if b.lasterr != '' {
		return error(b.lasterr)
	}
	if b.n == 0 {
		return
	}
	if n := b.writer.write(b.buf[0..b.n]) {
		if n < b.n {
			if n > 0 && n < b.n {
				copy(b.buf[0..b.n - n], b.buf[n..b.n])
			}
			b.n -= n
			b.lasterr = 'short write'
			return error(b.lasterr)
		} else {
			b.n = 0
			return
		}
	} else {
		b.lasterr = err.str()
		return err
	}
}

// available returns how many bytes are unused in the buffer.
pub fn (b Writer) available() int {
	return b.buf.len - b.n
}

// buffered returns the number of bytes that have been written into the current buffer.
pub fn (b Writer) buffered() int {
	return b.n
}

// write writes the contents of p into the buffer.
// It returns the number of bytes written.
pub fn (mut b Writer) write(buf []byte) ?int {
	if b.lasterr != '' {
		return error(b.lasterr)
	}
	mut sum := 0
	mut p := buf.clone()
	for p.len > b.available() {
		mut n := 0
		if b.buffered() == 0 {
			// Large write, empty buffer.
			// Write directly from p to avoid copy.
			n = b.writer.write(p) or {
				b.lasterr = err.str()
				return err
			}
		} else {
			n = copy(b.buf[b.n..], p)
			b.n += n
			b.flush() or {}
		}
		sum += n
		p = p[n..]
	}
	n := copy(b.buf[b.n..], p)
	b.n += n
	sum += n
	return sum
}
