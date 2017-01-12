#ifndef translation_de_Translation_h
#define translation_de_Translation_h

#include "translation/Translation.h"

namespace translation { namespace de {

class Translation : public translation::Translation
{
public:
  std::string HelloWorld() const override;
};

} } // namespace translation::de

#endif // ifndef translation_de_Translation_h
