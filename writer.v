module bufwriter

import io

const default_buf_size = 4096

// Writer implements buffering for an io.Writer object.
// If an error occurs writing to a Writer, no more data will be
// accepted and all subsequent writes, and Flush, will return the error.
// After all data has been written, the client should call the
// Flush method to guarantee all data has been forwarded to
// the underlying io.Writer.
pub struct Writer {
mut:
	buf     []byte
	lasterr string
	n       int
	wr      io.Writer
}

// new_size returns a new Writer whose buffer has at least the specified
// size. If the argument io.Writer is already a Writer with large enough
// size, it returns the underlying Writer.
pub fn new_size(w io.Writer, size int) &Writer {
	if w is Writer {
		if w.buf.len >= size {
			return w
		}
	}
	s := if size <= 0 { bufwriter.default_buf_size } else { size }
	return &Writer{
		buf: []byte{len: s}
		wr: w
	}
}

// new returns a new Writer whose buffer has the default size.
pub fn new(w io.Writer) &Writer {
	return new_size(w, bufwriter.default_buf_size)
}

// flush writes any buffered data to the underlying io.Writer.
pub fn (mut b Writer) flush() ? {
	if b.lasterr != '' {
		return error(b.lasterr)
	}
	if b.n == 0 {
		return
	}
	if n := b.wr.write(b.buf[0..b.n]) {
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
			n = b.wr.write(p) or {
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
