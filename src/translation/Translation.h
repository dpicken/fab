#ifndef translation_Translation_h
#define translation_Translation_h

#include "Translation.fwd.h"

#include <string>

namespace translation {

class Translation
{
public:
  virtual ~Translation();

  virtual std::string HelloWorld() const = 0;
};

} // namespace translation

#endif // ifndef translation_Translation_h
