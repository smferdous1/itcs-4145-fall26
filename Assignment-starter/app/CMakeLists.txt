add_executable(test_graph testGraph.cpp)
target_include_directories(test_graph PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
)

add_executable(test_bfs
    testBFS_level.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/bfs_visit.cpp
)
target_include_directories(test_bfs PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
)
