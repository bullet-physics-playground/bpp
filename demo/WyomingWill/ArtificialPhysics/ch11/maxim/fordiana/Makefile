SRC_DIR = src
CXX=		gcc

CXXFLAGS =	-O2 -g -Wall -fmessage-length=0

OBJS =		$(SRC_DIR)/coverage_simulation.o

LIBS =          -lglut -lm

TARGET =	coverage_sim

$(TARGET):	$(OBJS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(OBJS) $(LIBS)

all:	$(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)
