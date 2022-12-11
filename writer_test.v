module bufwriter

import takkyuuplayer.bytebuf

fn test_new() {
	w := bytebuf.Buffer{}
	{
		// no cap
		writer := new(writer: w)

		assert writer.buf == []u8{len: 4096}
		assert writer.n == 0
		if writer.writer is bytebuf.Buffer {
			assert writer.writer == w
		} else {
			assert false
		}
	}
	{
		// with cap
		writer := new(writer: w, cap: 1024)

		assert writer.buf == []u8{len: 1024}
	}
	{
		// idempotent
		writer := new(writer: w)
		w1 := new(writer: writer)

		assert w1.buf == writer.buf
		assert w1.n == writer.n
		if writer.writer is bytebuf.Buffer && w1.writer is bytebuf.Buffer {
			assert w1.writer == writer.writer
		} else {
			assert false
		}
	}
	{
		// idempotent as long as `cap` <= writer.buf.len
		writer := new(writer: w)
		w1 := new(writer: writer, cap: writer.buf.len - 1)

		assert w1.buf == writer.buf
		assert w1.n == writer.n
		if writer.writer is bytebuf.Buffer && w1.writer is bytebuf.Buffer {
			assert w1.writer == writer.writer
		} else {
			assert false
		}
	}
	{
		// idempotent as long as `cap` <= writer.buf.len
		writer := new(writer: w)
		w1 := new(writer: writer, cap: writer.buf.len + 1)

		assert w1.buf != writer.buf
		assert w1.n == writer.n
		if w1.writer is Writer {
			assert true
		} else {
			assert false
		}
	}
}

fn test_writer() ! {
	{
		// basic
		bufsizes := [u8(0), 16, 23, 32, 46, 64, 93, 128, 1024, 4096]

		mut data := []u8{len: 8192}
		for i := 0; i < data.len; i++ {
			data[i] = u8(` ` + i % (`~` - ` `))
		}

		mut w := bytebuf.Buffer{}
		for nwrite in bufsizes {
			for bs in bufsizes {
				w.reset()

				mut buf := new(writer: w, cap: bs)
				assert buf.write(data[..nwrite])! == nwrite
				buf.flush()!

				assert w.u8s() == data[..nwrite]
			}
		}
	}
	{
		mut w := bytebuf.Buffer{}
		mut buf := new(writer: w, cap: 2)

		assert buf.write([u8(1)])! == 1
		assert buf.write([u8(1), 2, 3, 4])! == 4
	}
	{
		// errors
		some_error := ErrShortWrite{}
		mut error_writer_tests := [
			ErrorWriterTestStruct{0, 1, none__, ErrShortWrite{
				msg: 'ShortWrite'
				written: 0
			}},
			ErrorWriterTestStruct{1, 2, none__, ErrShortWrite{
				msg: 'ShortWrite'
				written: 5
			}},
			ErrorWriterTestStruct{1, 1, none__, none__},
			ErrorWriterTestStruct{0, 1, some_error, some_error},
			ErrorWriterTestStruct{1, 2, some_error, some_error},
			ErrorWriterTestStruct{1, 1, some_error, some_error},
		]

		for mut w in error_writer_tests {
			mut buf := new(writer: w)
			buf.write('hello world'.bytes())!

			for i := 0; i < 2; i++ {
				if _ := buf.flush() {
				} else {
					match w.expect {
						ErrShortWrite {
							if err is ErrShortWrite {
								assert err == w.expect
							} else {
								assert err is ErrShortWrite
							}
						}
						else {
							assert false
						}
					}
				}
			}
		}
	}
}

struct ErrorWriterTestStruct {
	n      int
	m      int
	err    IError
	expect IError
}

fn (w ErrorWriterTestStruct) write(buf []u8) !int {
	if w.err !is None__ {
		return w.err
	}
	return buf.len * w.n / w.m
}

struct ErrWriterTest {
	msg  string = 'some error'
	code int
}
