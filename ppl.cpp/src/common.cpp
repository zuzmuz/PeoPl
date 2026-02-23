#ifndef PEOPL_COMMON_CPP
#define PEOPL_COMMON_CPP

#include <cstring>
#include <stdint.h>

typedef uint8_t u8;
typedef int8_t i8;
typedef uint16_t u16;
typedef int16_t i16;
typedef uint32_t u32;
typedef int32_t i32;
typedef uint64_t u64;
typedef int64_t i64;

typedef size_t usize;
typedef ptrdiff_t isize;

struct String {
	u8 * ptr;
	isize size;

	u8 const & operator[](usize i) { return ptr[i]; }

	bool operator==(String const & rhs) const {
		if (this->size != rhs.size) return false;
		return memcmp(this->ptr, rhs.ptr, size) == 0;
	}

	bool operator!=(String const & rhs) const {
		return not (*this == rhs);
	}
};

#endif
