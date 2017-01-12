#ifndef translation_en_Translation_h
#define translation_en_Translation_h

#include "translation/Translation.h"

namespace translation { namespace en {

class Translation : public translation::Translation
{
public:
  std::string HelloWorld() const override;
};

} } // namespace translation::en

#endif // ifndef translation_en_Translation_h
