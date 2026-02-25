#pragma once

#include <cstring>
#include <stdint.h>
#include <utility>

typedef uint8_t u8;
typedef int8_t i8;
typedef uint16_t u16;
typedef int16_t i16;
typedef uint32_t u32;
typedef int32_t i32;
typedef uint64_t u64;
typedef int64_t i64;

typedef size_t usize;

struct String {
	const u8 * data;
	usize size;

	String() {}

	String(const char * source) {
		data = (u8 *)source;
		size = strlen(source);
	}

	String(const u8 * data, usize size) : data(data), size(size) {}

	u8 const & operator[](usize i) const { return data[i]; }

	bool operator==(String const & rhs) const {
		if (this->size != rhs.size)
			return false;
		return memcmp(this->data, rhs.data, size) == 0;
	}

	bool operator!=(String const & rhs) const {
		return not(*this == rhs);
	}

	String substring(usize start, usize end) const {
		return String(data + start, end - start);
	}
};

template <typename T> struct Array {
  private:
	const T * data = nullptr;
	usize size = 0;

  public:
	usize capacity;

	Array() {}

	explicit Array(usize capacity) : capacity(capacity) {
		data = new T[capacity];
	}

	~Array() { delete[] data; }

	Array(const Array<T> &) = delete;
	Array(Array<T> && o) {
		data = o.data;
		o.data = nullptr;

		size = o.size;
		capacity = o.capacity;
	}

	Array<T> & operator=(const Array<T> &) = delete;
	Array<T> & operator=(Array<T> && o) {
		delete[] data;
		data = o.data;
		o.data = nullptr;

		size = o.size;
		capacity = o.capacity;
		return *this;
	};

	template <typename... Args> T & emplace_back(Args &&... args) {

		// construct in-place at the next free slot
		// T * slot = data + size;
		//
		// ::new (static_cast<void *>(slot))
		// 	T(std::forward<Args>(args)...);

		data[size] = T(std::forward(args)...);

		size += size;

		return data[size];
	}

	Array<T> const & operator[](usize i) const { return data[i]; }
};
